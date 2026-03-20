import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banner.dart';

class HomeBannerService {
  static const String apiUrl =
      'https://raw.githubusercontent.com/liubquanti/White-Cobalt/refs/heads/main/files/banner.json';

  static Future<HomeBanner?> fetchBannerForLanguage(String languageCode) async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load banner: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final normalizedCode = languageCode.toLowerCase().split('-').first;

    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final link = (entry['link'] ?? '').toString();
      final image = (entry['image'] ?? '').toString();
      final localisations = entry['localisations'];

      if (link.isEmpty || image.isEmpty || localisations is! Map<String, dynamic>) {
        continue;
      }

      Map<String, dynamic>? localeData;

      if (localisations[normalizedCode] is Map<String, dynamic>) {
        localeData = localisations[normalizedCode] as Map<String, dynamic>;
      } else if (localisations['en'] is Map<String, dynamic>) {
        localeData = localisations['en'] as Map<String, dynamic>;
      } else {
        final firstLocale = localisations.values.firstWhere(
          (value) => value is Map<String, dynamic>,
          orElse: () => <String, dynamic>{},
        );
        if (firstLocale is Map<String, dynamic>) {
          localeData = firstLocale;
        }
      }

      if (localeData == null) {
        continue;
      }

      return HomeBanner(
        link: link,
        image: image,
        localization: BannerLocalization.fromJson(localeData),
      );
    }

    return null;
  }
}
