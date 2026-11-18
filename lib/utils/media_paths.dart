/// Where downloads are stored and how they are named.
///
/// Files go to `<public media dir>/Cobalt/<service>/<file>`, where the public
/// directory depends on the media type. The storage screen scans the same
/// folders, so both must use this single definition.
abstract final class MediaPaths {
  static const _root = '/storage/emulated/0';
  static const download = '$_root/Download';
  static const pictures = '$_root/Pictures';
  static const movies = '$_root/Movies';
  static const music = '$_root/Music';
  static const appFolder = 'Cobalt';

  static const publicDirs = [download, pictures, movies, music];

  static List<String> get appDirs => [for (final dir in publicDirs) '$dir/$appFolder'];

  static const _imageExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'};
  static const _videoExt = {'mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', '3gp', 'wmv'};
  static const _audioExt = {'mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac', 'opus', 'wma'};

  static String publicDirFor(String filename) {
    final dot = filename.lastIndexOf('.');
    final ext = dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
    if (_imageExt.contains(ext)) return pictures;
    if (_videoExt.contains(ext)) return movies;
    if (_audioExt.contains(ext)) return music;
    return download;
  }

  /// Server responses (filenames, service names) are untrusted input and
  /// must never be used to build filesystem paths as-is: a malicious cobalt
  /// instance could otherwise return `../../secret` to write outside the
  /// download directory. Strips separators, traversal sequences and control
  /// characters, leaving a single flat path component.
  static String sanitize(String input, {required String fallback}) {
    final cleaned = input
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(RegExp(r'\.\.+'), '_')
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
        .trim();
    return (cleaned.isEmpty || cleaned == '.') ? fallback : cleaned;
  }

  /// Folder name for a download: the service reported by the API, else the
  /// prefix of a `service_xxx.ext` filename, else the source site's domain.
  static String serviceFolder({
    required String? reportedService,
    required String filename,
    required String sourceUrl,
    required String fallback,
  }) {
    if (reportedService != null && reportedService.isNotEmpty) {
      return sanitize(reportedService.toLowerCase(), fallback: fallback);
    }

    final underscore = filename.indexOf('_');
    if (underscore > 0) {
      final prefix = filename.substring(0, underscore).toLowerCase();
      if (prefix != 'cobalt') return sanitize(prefix, fallback: fallback);
    }

    final host = Uri.tryParse(sourceUrl)?.host.toLowerCase() ?? '';
    final parts = host.split('.');
    if (parts.length > 1) {
      final name = parts.first == 'www' && parts.length > 2 ? parts[1] : parts[parts.length - 2];
      return sanitize(name, fallback: fallback);
    }
    return fallback;
  }
}
