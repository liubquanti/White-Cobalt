import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/changelog_entry.dart';
import '../services/remote_data.dart';
import '../utils/logger.dart';

/// Paginated cobalt changelog feed for the home screen.
class ChangelogController extends ChangeNotifier {
  static const pageSize = 3;

  List<ChangelogFile> _files = const [];
  final List<ChangelogEntry> _entries = [];
  int _loaded = 0;
  bool _started = false;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _disposed = false;

  List<ChangelogEntry> get entries => List.unmodifiable(_entries);
  bool get initialLoading => _initialLoading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _loaded < _files.length;

  /// Starts loading once; later calls are no-ops.
  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    try {
      _files = await RemoteData.changelogFiles();
      await loadMore();
    } catch (e) {
      logDebug('Changelog list failed: $e');
    } finally {
      _initialLoading = false;
      _notify();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    _notify();

    final end = min(_loaded + pageSize, _files.length);
    final page = _files.sublist(_loaded, end);
    final results = await Future.wait(page.map((file) async {
      try {
        return await RemoteData.changelog(file);
      } catch (e) {
        logDebug('Changelog ${file.version} failed: $e');
        return null;
      }
    }));

    _entries.addAll(results.whereType<ChangelogEntry>());
    _loaded = end;
    _loadingMore = false;
    _initialLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
