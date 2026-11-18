import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../generated/codegen_loader_keys.g.dart';
import '../models/cobalt_response.dart';
import '../models/server_config.dart';
import '../services/cobalt_api.dart';
import '../services/download_service.dart';
import '../services/http_client.dart';
import '../services/native_bridge.dart';
import '../services/remote_data.dart';
import '../services/server_repository.dart';
import '../utils/logger.dart';
import '../utils/media_paths.dart';
import 'settings_controller.dart';

enum StatusKind { info, success, error }

/// Status line shown on the home screen. Typed, so the UI no longer has to
/// guess the state by searching the *translated* text for words like
/// "Error" or "Complete" (which broke in other languages).
class StatusMessage {
  const StatusMessage(this.kind, this.text);

  const StatusMessage.info(this.text) : kind = StatusKind.info;
  const StatusMessage.success(this.text) : kind = StatusKind.success;
  const StatusMessage.error(this.text) : kind = StatusKind.error;

  final StatusKind kind;
  final String text;
}

/// State and logic of the home screen: servers, requests and downloads.
class HomeController extends ChangeNotifier {
  HomeController({required this.settings, ServerRepository? repository})
      : _repo = repository ?? ServerRepository();

  final SettingsController settings;
  final ServerRepository _repo;
  final _ready = Completer<void>();
  bool _disposed = false;

  List<ServerConfig> _servers = const [];
  ServerConfig? _selected;
  ServerInfo? _serverInfo;
  StatusMessage? _status;
  CobaltResponse? _response;
  bool _checkingServer = false;
  bool _requesting = false;
  bool _downloading = false;
  bool _downloadSucceeded = false;
  String? _progressLabel;
  bool _showCopied = false;
  String _sourceUrl = '';
  Timer? _copiedTimer;
  Timer? _stallTimer;

  List<ServerConfig> get servers => _servers;
  ServerConfig? get selected => _selected;
  ServerInfo? get serverInfo => _serverInfo;
  StatusMessage? get status => _status;
  bool get checkingServer => _checkingServer;
  bool get requesting => _requesting;
  bool get downloading => _downloading;
  bool get downloadSucceeded => _downloadSucceeded;
  String? get progressLabel => _progressLabel;
  bool get showCopied => _showCopied;

  /// A request or download is running; inputs are locked.
  bool get busy => _requesting || _downloading;

  /// Completes once saved servers are loaded.
  Future<void> get ready => _ready.future;

  CobaltResponse? get errorResponse =>
      _response?.status == CobaltStatus.error ? _response : null;

  List<PickerItem> get pickerItems =>
      _response?.status == CobaltStatus.picker ? _response!.picker : const [];

  // ---------------------------------------------------------------- servers

  Future<void> init() async {
    unawaited(DownloadService.requestPermissions());
    try {
      final stored = await _repo.load();
      if (stored.servers.isNotEmpty) {
        _servers = stored.servers;
        _selected = _servers.firstWhere(
          (s) => s.url == stored.selectedUrl,
          orElse: () => _servers.first,
        );
        _notify();
        await _repo.markInitialized();
        unawaited(_refreshOfficialMetadata());
        unawaited(refreshServerInfo());
      } else if (stored.isFirstLaunch) {
        await _addDefaultServers();
        await _repo.markInitialized();
      } else {
        _setNoServers();
      }
    } catch (e) {
      logDebug('Loading servers failed: $e');
      _setNoServers();
    } finally {
      _ready.complete();
    }
  }

  void _setNoServers() {
    _servers = const [];
    _selected = null;
    _serverInfo = null;
    _status = StatusMessage.info(LocaleKeys.NoServersConfiguredPleaseAddACobaltServer.tr());
    _notify();
  }

  /// First launch: add the official servers flagged `autoadd`.
  Future<void> _addDefaultServers() async {
    try {
      final official = await RemoteData.officialServers();
      final defaults = [
        for (final s in official.where((s) => s.autoAdd))
          ServerConfig(url: s.apiUrl, name: s.name, isOfficial: true),
      ];
      if (defaults.isEmpty) return _setNoServers();
      _servers = defaults;
      _selected = defaults.first;
      await _persist();
      unawaited(refreshServerInfo());
    } catch (e) {
      logDebug('Default servers unavailable: $e');
      _setNoServers();
    }
  }

  /// Keeps names/official flags of saved servers in sync with servers.json.
  Future<void> _refreshOfficialMetadata() async {
    try {
      final official = {for (final s in await RemoteData.officialServers()) s.apiUrl: s};
      var changed = false;
      final updated = <ServerConfig>[];
      for (final server in _servers) {
        final match = official[server.url];
        if (match == null) {
          updated.add(server);
          continue;
        }
        final name = match.name?.trim();
        final next = server.copyWith(
          name: (name != null && name.isNotEmpty) ? name : server.name,
          isOfficial: true,
        );
        changed |= next.name != server.name || !server.isOfficial;
        updated.add(next);
      }
      _servers = updated;
      if (_selected != null) {
        _selected = _servers.firstWhere((s) => s.url == _selected!.url, orElse: () => _selected!);
      }
      if (changed) {
        _notify();
        await _repo.saveServers(_servers);
      }
    } catch (_) {
      // Keep the saved list as-is when servers.json is unreachable.
    }
  }

  Future<void> refreshServerInfo() async {
    final server = _selected;
    _serverInfo = null;
    if (server == null) {
      _checkingServer = false;
      _status = StatusMessage.info(LocaleKeys.NoServerSelected.tr());
      _notify();
      return;
    }

    _checkingServer = true;
    _status = StatusMessage.info(LocaleKeys.CheckingServer.tr());
    _notify();

    StatusMessage status;
    ServerInfo? info;
    try {
      info = await CobaltApi.fetchInfo(server.url);
      status = StatusMessage.success(LocaleKeys.ConnectedToCobalt.tr(args: [info.version]));
    } catch (e) {
      status = _serverError(e);
    }

    // Ignore results for a server that is no longer selected.
    if (_selected?.url != server.url) return;
    _serverInfo = info;
    _status = status;
    _checkingServer = false;
    _notify();
  }

  StatusMessage _serverError(Object e) {
    logDebug('Server check failed: $e');
    return switch (e) {
      NotCobaltServerException() => StatusMessage.error(LocaleKeys.ErrorNotAValidCobaltServer.tr()),
      FormatException() => StatusMessage.error(LocaleKeys.ErrorNotAValidCobaltServer.tr()),
      HttpStatusException(:final statusCode) =>
        StatusMessage.error(LocaleKeys.ServerErrorWithArg.tr(args: ['$statusCode'])),
      _ => StatusMessage.error(LocaleKeys.ConnectionError.tr(args: ['$e'])),
    };
  }

  Future<void> selectServer(String url) async {
    if (busy || url == _selected?.url) return;
    final server = _servers.where((s) => s.url == url).firstOrNull;
    if (server == null) return;
    _selected = server;
    _response = null;
    unawaited(_repo.saveSelected(url));
    await refreshServerInfo();
  }

  /// Verifies and adds a server typed by the user.
  Future<void> addCustomServer(String rawUrl, String? apiKey) async {
    final url = ServerConfig.normalizeUrl(rawUrl);
    if (url == null) {
      _status = StatusMessage.error(LocaleKeys.ErrorNotAValidCobaltServer.tr());
      _notify();
      return;
    }
    if (_servers.any((s) => s.url == url)) return selectServer(url);

    _checkingServer = true;
    _status = StatusMessage.info(LocaleKeys.VerifyingServer.tr());
    _notify();
    try {
      final info = await CobaltApi.fetchInfo(url);
      final server = ServerConfig(url: url, apiKey: apiKey);
      _servers = [..._servers, server];
      _selected = server;
      _serverInfo = info;
      _response = null;
      _status = StatusMessage.success(LocaleKeys.ConnectedToCobalt.tr(args: [info.version]));
      await _persist();
    } catch (e) {
      _status = _serverError(e);
    } finally {
      _checkingServer = false;
      _notify();
    }
  }

  /// Adds (or re-selects) a server picked in the server browser.
  Future<void> addServer(ServerConfig server) async {
    final index = _servers.indexWhere((s) => s.url == server.url);
    if (index < 0) {
      _servers = [..._servers, server];
      _selected = server;
    } else {
      final existing = _servers[index];
      final updated = server.hasApiKey ? existing.copyWith(apiKey: server.apiKey) : existing;
      _servers = [..._servers]..[index] = updated;
      _selected = updated;
    }
    _response = null;
    await _persist();
    await refreshServerInfo();
  }

  Future<void> deleteServer(String url) async {
    _servers = _servers.where((s) => s.url != url).toList();
    final wasSelected = _selected?.url == url;
    if (wasSelected) {
      _selected = _servers.firstOrNull;
      _response = null;
    }
    await _persist();
    if (wasSelected) {
      await refreshServerInfo();
    } else {
      _notify();
    }
  }

  Future<void> _persist() async {
    await _repo.saveServers(_servers);
    await _repo.saveSelected(_selected?.url);
  }

  // --------------------------------------------------------------- settings

  void setDownloadMode(String mode) => settings.update((s) => s.copyWith(downloadMode: mode));

  void toggleShareLinks() => settings.update((s) => s.copyWith(shareLinks: !s.shareLinks));

  // -------------------------------------------------------------- requests

  /// Called with a URL that arrived through the Android share sheet.
  Future<void> handleSharedUrl(String url) async {
    await ready;
    if (_selected == null) {
      _status = StatusMessage.info(LocaleKeys.URLReceivedFromShareButPleaseSelectAServerFirst.tr());
      _notify();
      return;
    }
    if (settings.value.autoDownloadFromShare && !busy) await process(url);
  }

  Future<void> process(String rawUrl) async {
    final server = _selected;
    final url = rawUrl.trim();
    if (busy) return;
    if (server == null) {
      _status = StatusMessage.info(LocaleKeys.PleaseAddAndSelectAServerFirst.tr());
      return _notify();
    }
    if (url.isEmpty) {
      _status = StatusMessage.info(LocaleKeys.PleaseEnterAURL.tr());
      return _notify();
    }

    _sourceUrl = url;
    _requesting = true;
    _response = null;
    _status = StatusMessage.info(LocaleKeys.ProcessingRequest.tr());
    _notify();

    try {
      final response = await CobaltApi.request(server: server, mediaUrl: url, settings: settings.value);
      _response = response;
      _requesting = false;

      switch (response.status) {
        case CobaltStatus.tunnel:
        case CobaltStatus.redirect:
        case CobaltStatus.localProcessing:
          final link = response.url;
          if (link == null) {
            _status = StatusMessage.error(LocaleKeys.LocalProcessingErrorInvalidResponseFormat.tr());
            break;
          }
          _status = StatusMessage.info(
            response.status == CobaltStatus.localProcessing
                ? LocaleKeys.LocalProcessingWithArg.tr(args: [response.processingType ?? ''])
                : LocaleKeys.ResponseReceivedWithArg.tr(args: [response.rawStatus ?? '']),
          );
          await _deliver(CobaltApi.resolveMediaUrl(link, server.url), response.filename);
        case CobaltStatus.picker:
          _status = StatusMessage.info(LocaleKeys.ResponseReceivedWithArg.tr(args: ['picker']));
        case CobaltStatus.error:
          _status = StatusMessage.error(
            response.isAuthKeyMissing
                ? LocaleKeys.APIKeyRequired.tr()
                : LocaleKeys.ErrorWithArg.tr(args: [response.errorCode ?? '?']),
          );
        case CobaltStatus.unknown:
          _status = StatusMessage.error(LocaleKeys.ErrorWithArg.tr(args: [response.rawStatus ?? '?']));
      }
    } on HttpStatusException catch (e) {
      _status = StatusMessage.error(LocaleKeys.RequestError.tr(args: ['${e.statusCode}']));
    } catch (e) {
      logDebug('Request failed: $e');
      _status = StatusMessage.error(LocaleKeys.ErrorWithArg.tr(args: ['$e']));
    } finally {
      _requesting = false;
      _notify();
    }
  }

  Future<void> downloadPickerItem(PickerItem item) async {
    final server = _selected;
    if (server == null || busy) return;
    final link = CobaltApi.resolveMediaUrl(item.url, server.url);
    await _deliver(link, 'cobalt_${DateTime.now().millisecondsSinceEpoch}${item.extension}');
    _notify();
  }

  /// Shares or downloads [link] depending on the "share links" setting.
  Future<void> _deliver(String link, String? rawFilename) async {
    if (settings.value.shareLinks) return _shareLink(link);

    final filename = MediaPaths.sanitize(
      rawFilename ?? '',
      fallback: 'cobalt_${DateTime.now().millisecondsSinceEpoch}',
    );
    final folder = MediaPaths.serviceFolder(
      reportedService: _response?.service,
      filename: filename,
      sourceUrl: _sourceUrl,
      fallback: LocaleKeys.Other.tr(),
    );
    await _download(link, filename, folder);
  }

  Future<void> _shareLink(String link) async {
    if (settings.value.shareCopyToClipboard) {
      await Clipboard.setData(ClipboardData(text: link));
      _status = StatusMessage.success(LocaleKeys.LinkCopiedToClipboard.tr());
      _showCopied = true;
      _copiedTimer?.cancel();
      _copiedTimer = Timer(const Duration(seconds: 2), () {
        _showCopied = false;
        _notify();
      });
    } else {
      await NativeBridge.shareText(link);
      _status = StatusMessage.success(LocaleKeys.LinkShared.tr());
    }
    _notify();
  }

  Future<void> _download(String link, String filename, String folder) async {
    _downloading = true;
    _downloadSucceeded = false;
    _progressLabel = LocaleKeys.DownloadingWithArg.tr(args: ['0%']);
    _armStallTimer();
    _notify();

    try {
      await DownloadService.download(
        url: link,
        filename: filename,
        serviceFolder: folder,
        onUpdate: _onDownloadUpdate,
      );
      _stallTimer?.cancel();
      _downloadSucceeded = true;
      _progressLabel = LocaleKeys.DownloadComplete.tr();
      _status = StatusMessage.success(LocaleKeys.DownloadComplete.tr());
      _notify();
      await Future<void>.delayed(const Duration(milliseconds: 800));
    } on DownloadException catch (e) {
      _status = StatusMessage.error(switch (e.reason) {
        DownloadFailure.failed => LocaleKeys.DownloadFailed.tr(),
        DownloadFailure.canceled => LocaleKeys.DownloadCanceled.tr(),
        DownloadFailure.fileMissing => LocaleKeys.DownloadFailedFileNotFound.tr(),
        DownloadFailure.io => LocaleKeys.ErrorProcessingFile.tr(args: ['$e']),
      });
    } catch (e) {
      logDebug('Download failed: $e');
      _status = StatusMessage.error(LocaleKeys.DownloadError.tr(args: ['$e']));
    } finally {
      _stallTimer?.cancel();
      _downloading = false;
      _downloadSucceeded = false;
      _progressLabel = null;
      _notify();
    }
  }

  void _onDownloadUpdate(DownloadUpdate update) {
    _progressLabel = switch (update.phase) {
      DownloadPhase.queued => LocaleKeys.DownloadInQueue.tr(),
      DownloadPhase.running => LocaleKeys.DownloadingWithArg.tr(args: ['${update.progress}%']),
      DownloadPhase.paused => LocaleKeys.DownloadPaused.tr(),
      DownloadPhase.finalizing => LocaleKeys.Processing.tr(),
    };
    if (update.phase == DownloadPhase.running) _armStallTimer();
    _notify();
  }

  /// After 10 s without progress, append "(still downloading...)" once.
  void _armStallTimer() {
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 10), () {
      final label = _progressLabel;
      if (!_downloading || label == null) return;
      _progressLabel = LocaleKeys.stillDownloading.tr(args: [label]);
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _copiedTimer?.cancel();
    _stallTimer?.cancel();
    super.dispose();
  }
}
