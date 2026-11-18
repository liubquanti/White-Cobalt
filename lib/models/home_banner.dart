/// Promotional banner shown on the home screen (files/banner.json).
class HomeBanner {
  const HomeBanner({
    required this.link,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String link;
  final String image;
  final String title;
  final String subtitle;

  /// Picks the first valid entry, localised to [languageCode] with fallback
  /// to English and then to any available localisation.
  static HomeBanner? pick(Object? json, String languageCode) {
    if (json is! List) return null;
    final code = languageCode.toLowerCase().split('-').first;

    for (final entry in json.whereType<Map<String, dynamic>>()) {
      final link = entry['link']?.toString() ?? '';
      final image = entry['image']?.toString() ?? '';
      final localisations = entry['localisations'];
      if (link.isEmpty || image.isEmpty || localisations is! Map<String, dynamic>) continue;

      final locale = [localisations[code], localisations['en'], ...localisations.values]
          .whereType<Map<String, dynamic>>()
          .firstOrNull;
      if (locale == null) continue;

      return HomeBanner(
        link: link,
        image: image,
        title: locale['title']?.toString() ?? '',
        subtitle: locale['subtitle']?.toString() ?? '',
      );
    }
    return null;
  }
}
