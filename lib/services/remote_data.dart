import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_urls.dart';
import '../models/changelog_entry.dart';
import '../models/home_banner.dart';
import '../models/instances.dart';
import '../models/misc.dart';
import '../utils/formatters.dart';
import 'http_client.dart';

class InstanceLists {
  const InstanceLists({required this.official, required this.kwiat, required this.hyper});

  final List<OfficialServer> official;
  final List<CobaltInstance> kwiat;
  final List<CobaltInstance> hyper;

  bool get isEmpty => official.isEmpty && kwiat.isEmpty && hyper.isEmpty;
}

/// Read-only data fetched from GitHub and third-party trackers.
abstract final class RemoteData {
  static Future<List<OfficialServer>> officialServers() async {
    final json = await AppHttp.getJson(AppUrls.officialServers);
    if (json is! List) return const [];
    return json.whereType<Map<String, dynamic>>().map(OfficialServer.fromJson).toList();
  }

  /// Loads all three sources in parallel. A failing source just yields an
  /// empty list; throws only when every source failed.
  static Future<InstanceLists> instanceLists() async {
    Object? lastError;
    Future<List<T>> guard<T>(Future<List<T>> future) async {
      try {
        return await future;
      } catch (e) {
        lastError = e;
        return <T>[];
      }
    }

    final results = await Future.wait([
      guard(officialServers()),
      guard(_kwiat()),
      guard(_hyper()),
    ]);
    final lists = InstanceLists(
      official: results[0] as List<OfficialServer>,
      kwiat: results[1] as List<CobaltInstance>,
      hyper: results[2] as List<CobaltInstance>,
    );
    if (lists.isEmpty && lastError != null) throw lastError!;
    return lists;
  }

  static Future<List<CobaltInstance>> _kwiat() async {
    final json = await AppHttp.getJson(AppUrls.kwiatInstances);
    if (json is! List) throw const FormatException('kwiat: expected a list');
    return _dedupeAndSort(json.whereType<Map<String, dynamic>>().map(CobaltInstance.fromKwiatJson));
  }

  static Future<List<CobaltInstance>> _hyper() async {
    final json = await AppHttp.getJson(AppUrls.hyperInstances);
    final data = json is Map ? json['data'] : null;
    if (data is! List) throw const FormatException('hyper: missing data array');
    return _dedupeAndSort(
      data.whereType<Map<String, dynamic>>().where((e) => e['api'] is String).map(CobaltInstance.fromHyperJson),
    );
  }

  static List<CobaltInstance> _dedupeAndSort(Iterable<CobaltInstance> instances) {
    final seen = <String>{};
    return instances.where((i) => seen.add(i.apiUrl.toLowerCase())).toList()
      ..sort(CobaltInstance.byAvailability);
  }

  static Future<HomeBanner?> banner(String languageCode) async {
    return HomeBanner.pick(await AppHttp.getJson(AppUrls.homeBanner), languageCode);
  }

  /// Changelog files, newest first.
  static Future<List<ChangelogFile>> changelogFiles() async {
    final json = await AppHttp.getJson(
      AppUrls.cobaltChangelogs,
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (json is! List) return const [];
    final files = <ChangelogFile>[];
    for (final item in json.whereType<Map>()) {
      final name = item['name']?.toString() ?? '';
      final url = item['download_url']?.toString();
      if (name.endsWith('.md') && url != null) {
        files.add(ChangelogFile(version: name.substring(0, name.length - 3), downloadUrl: url));
      }
    }
    return files..sort((a, b) => compareVersions(b.version, a.version));
  }

  static Future<ChangelogEntry?> changelog(ChangelogFile file) async {
    return ChangelogEntry.parse(file.version, await AppHttp.getText(file.downloadUrl));
  }

  static Future<List<MonitorStatus>> serviceStatus() async {
    return MonitorStatus.listFromJson(await AppHttp.getJson(AppUrls.statusApi));
  }

  /// Latest released version (from pubspec.yaml on main), without build no.
  static Future<String?> latestAppVersion() async {
    final text = await AppHttp.getText(AppUrls.remotePubspec);
    for (final line in text.split('\n')) {
      if (line.startsWith('version:')) {
        return line.substring('version:'.length).trim().split('+').first.trim();
      }
    }
    return null;
  }

  static Future<PackageInfo> packageInfo() => PackageInfo.fromPlatform();
}
