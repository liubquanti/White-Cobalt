/// One cobalt release note (web/changelogs/<version>.md in imputnet/cobalt).
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.title,
    required this.date,
    required this.content,
    this.bannerFile,
  });

  final String version;
  final String title;
  final String date;
  final String content;
  final String? bannerFile;

  /// Parses the YAML-ish front matter (`title`, `date`, `banner.file`)
  /// followed by the markdown body. Returns null when required fields are
  /// missing.
  static ChangelogEntry? parse(String version, String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;

    String title = '';
    String date = '';
    String? bannerFile;
    var inBanner = false;
    var bodyStart = -1;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim() == '---') {
        bodyStart = i + 1;
        break;
      }
      final trimmed = line.trim();
      if (line.startsWith('title:')) {
        title = _value(line);
      } else if (line.startsWith('date:')) {
        date = _value(line);
      } else if (line.startsWith('banner:')) {
        inBanner = true;
      } else if (inBanner && trimmed.startsWith('file:')) {
        bannerFile = _value(trimmed);
      } else if (trimmed.isEmpty || !line.startsWith(' ')) {
        inBanner = false;
      }
    }

    if (bodyStart < 0 || title.isEmpty || date.isEmpty) return null;
    return ChangelogEntry(
      version: version,
      title: title,
      date: date,
      content: lines.sublist(bodyStart).join('\n').trim(),
      bannerFile: (bannerFile?.isEmpty ?? true) ? null : bannerFile,
    );
  }

  /// Value after the first `:` with surrounding quotes removed. Unlike
  /// `split(':')[1]` this keeps values that themselves contain colons.
  static String _value(String line) {
    final value = line.substring(line.indexOf(':') + 1).trim();
    return value.replaceAll('"', '');
  }

  /// Plain-text preview for list cards.
  String get preview {
    final runes = content.runes;
    return runes.length > 150 ? '${String.fromCharCodes(runes.take(150))}...' : content;
  }
}

/// A changelog file listed by the GitHub contents API (not yet downloaded).
class ChangelogFile {
  const ChangelogFile({required this.version, required this.downloadUrl});

  final String version;
  final String downloadUrl;
}
