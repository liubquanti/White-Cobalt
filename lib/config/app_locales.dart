import 'package:flutter/widgets.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

/// Supported UI languages and how they are presented in the language picker.
abstract final class AppLocales {
  static const fallback = Locale('en');

  /// Language code -> flag. Order defines the supported-locale order.
  static const _flags = {
    'en': '🇬🇧', 'uk': '🇺🇦', 'de': '🇩🇪', 'fr': '🇫🇷', 'hi': '🇮🇳', 'zh': '🇨🇳',
    'es': '🇪🇸', 'pt': '🇵🇹', 'ru': '🇷🇺', 'ja': '🇯🇵', 'it': '🇮🇹', 'nl': '🇳🇱',
    'pl': '🇵🇱', 'cs': '🇨🇿', 'sl': '🇸🇮', 'hu': '🇭🇺', 'ro': '🇷🇴', 'bg': '🇧🇬',
    'el': '🇬🇷', 'tr': '🇹🇷', 'ar': '🇸🇦', 'th': '🇹🇭', 'sv': '🇸🇪', 'ko': '🇰🇷',
    'af': '🇿🇦', 'az': '🇦🇿', 'id': '🇮🇩', 'ms': '🇲🇾', 'bs': '🇧🇦', 'ca': '🇦🇩',
    'da': '🇩🇰', 'et': '🇪🇪', 'fil': '🇵🇭', 'hr': '🇭🇷', 'zu': '🇿🇦', 'is': '🇮🇸',
    'sw': '🇰🇪', 'lv': '🇱🇻', 'lt': '🇱🇹', 'no': '🇳🇴', 'uz': '🇺🇿', 'sq': '🇦🇱',
    'sk': '🇸🇰', 'fi': '🇫🇮', 'vi': '🇻🇳', 'ky': '🇰🇬', 'kk': '🇰🇿', 'mk': '🇲🇰',
    'mn': '🇲🇳', 'sr': '🇷🇸', 'ka': '🇬🇪', 'hy': '🇦🇲', 'he': '🇮🇱', 'ur': '🇵🇰',
    'fa': '🇮🇷', 'am': '🇪🇹', 'ne': '🇳🇵', 'bn': '🇧🇩', 'si': '🇱🇰', 'lo': '🇱🇦',
    'my': '🇲🇲', 'km': '🇰🇭',
  };

  static const _traditionalChinese = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

  static const _flagOverrides = {'zh-Hant': '🇹🇼'};
  static const _nameOverrides = {'fil': 'Filipino', 'zh-Hant': '繁體中文'};

  static final List<Locale> supported = [
    for (final code in _flags.keys) Locale(code),
    _traditionalChinese,
  ];

  static String flag(Locale locale) =>
      _flagOverrides[locale.toLanguageTag()] ?? _flags[locale.languageCode] ?? '🏳️';

  /// Native, capitalised language name (e.g. "Українська").
  static String nativeName(Locale locale) {
    final tag = locale.toLanguageTag();
    final name = _nameOverrides[tag] ?? LocaleNamesLocalizationsDelegate.nativeLocaleNames[tag] ?? tag;
    return name.isEmpty ? tag : name[0].toUpperCase() + name.substring(1);
  }
}
