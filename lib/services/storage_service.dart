import 'dart:io';

import '../models/misc.dart';
import '../utils/logger.dart';
import '../utils/media_paths.dart';

/// Scans and cleans the folders White Cobalt downloads into.
abstract final class StorageService {
  /// Bytes per service folder, merged across all public media dirs,
  /// largest first.
  static Future<List<ServiceUsage>> scan() async {
    final totals = <String, int>{};
    for (final path in MediaPaths.appDirs) {
      final root = Directory(path);
      if (!await root.exists()) continue;
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final size = await _sizeOf(entity);
        if (size > 0) {
          final name = entity.path.split('/').last;
          totals[name] = (totals[name] ?? 0) + size;
        }
      }
    }
    return [for (final e in totals.entries) ServiceUsage(e.key, e.value)]
      ..sort((a, b) => b.bytes.compareTo(a.bytes));
  }

  static Future<int> _sizeOf(Directory dir) async {
    var size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) size += await entity.length();
      }
    } catch (e) {
      logDebug('Size of ${dir.path} failed: $e');
    }
    return size;
  }

  /// Deletes the service folder from every media dir. Returns whether
  /// anything was deleted.
  static Future<bool> deleteService(String service) async {
    final safe = MediaPaths.sanitize(service, fallback: '');
    if (safe.isEmpty || safe != service) return false;
    var deleted = false;
    for (final path in MediaPaths.appDirs) {
      final dir = Directory('$path/$safe');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        deleted = true;
      }
    }
    return deleted;
  }
}
