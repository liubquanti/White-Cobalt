import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:white_cobalt/generated/codegen_loader_keys.g.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceLocales = _deviceLocales(context);
    final otherLocales = _alphabeticallySortedLocales(context, exclude: deviceLocales);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(LocaleKeys.ChangeLanguage.tr()),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: SvgPicture.string(
            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-chevron-left"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 6l-6 6l6 6" /></svg>',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(left: 16.0, right: 16.0, bottom: MediaQuery.of(context).padding.bottom),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              if (deviceLocales.isNotEmpty) ...[
                ...deviceLocales.map((locale) => _buildLanguageCard(context, locale)),
                const Divider(
                  color: Color(0xFF383838),
                  thickness: 1.0,
                  height: 1,
                ),
                const SizedBox(height: 10),
              ],
              ...otherLocales.map((locale) => _buildLanguageCard(context, locale)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Supported locales matching the system's language preferences, in the
  /// same priority order the OS reports them (most preferred first).
  List<Locale> _deviceLocales(BuildContext context) {
    final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
    final supportedLocales = context.supportedLocales;

    final matched = <Locale>[];
    for (final systemLocale in systemLocales) {
      for (final locale in supportedLocales) {
        if (matched.contains(locale)) continue;
        if (_matchesSystemLocale(locale, systemLocale)) {
          matched.add(locale);
          break;
        }
      }
    }

    return matched;
  }

  bool _matchesSystemLocale(Locale supported, Locale system) {
    if (supported.languageCode != system.languageCode) return false;
    if (supported.scriptCode != null && system.scriptCode != null) {
      return supported.scriptCode == system.scriptCode;
    }
    return true;
  }

  List<Locale> _alphabeticallySortedLocales(BuildContext context, {List<Locale> exclude = const []}) {
    final locales = List<Locale>.from(context.supportedLocales)
      ..removeWhere((locale) => exclude.contains(locale));

    locales.sort(
      (a, b) => _localeName(a).toLowerCase().compareTo(_localeName(b).toLowerCase()),
    );

    return locales;
  }

  Widget _buildLanguageCard(BuildContext context, Locale locale) {
    final isSelected = context.locale == locale;
    final name = _localeName(locale);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(9.5),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            onTap: () {
              context.setLocale(locale);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _localeFlag(locale),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-check"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l5 5l10 -10" /></svg>',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _localeName(Locale locale) {
    final tag = locale.toLanguageTag();
    final name = _nameOverridesByLanguageTag[tag] ??
        LocaleNamesLocalizationsDelegate.nativeLocaleNames[tag] ??
        tag;
    return name[0].toUpperCase() + name.substring(1);
  }

  static const _flagsByLanguageCode = {
    'en': '🇬🇧',
    'uk': '🇺🇦',
    'de': '🇩🇪',
    'fr': '🇫🇷',
    'hi': '🇮🇳',
    'zh': '🇨🇳',
    'es': '🇪🇸',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'it': '🇮🇹',
    'nl': '🇳🇱',
    'pl': '🇵🇱',
    'cs': '🇨🇿',
    'sl': '🇸🇮',
    'hu': '🇭🇺',
    'ro': '🇷🇴',
    'bg': '🇧🇬',
    'el': '🇬🇷',
    'tr': '🇹🇷',
    'ar': '🇸🇦',
    'th': '🇹🇭',
    'sv': '🇸🇪',
    'ko': '🇰🇷',
    'af': '🇿🇦',
    'az': '🇦🇿',
    'id': '🇮🇩',
    'ms': '🇲🇾',
    'bs': '🇧🇦',
    'ca': '🇦🇩',
    'da': '🇩🇰',
    'et': '🇪🇪',
    'fil': '🇵🇭',
    'hr': '🇭🇷',
    'zu': '🇿🇦',
    'is': '🇮🇸',
    'sw': '🇰🇪',
    'lv': '🇱🇻',
    'lt': '🇱🇹',
    'no': '🇳🇴',
    'uz': '🇺🇿',
    'sq': '🇦🇱',
    'sk': '🇸🇰',
    'fi': '🇫🇮',
    'vi': '🇻🇳',
    'ky': '🇰🇬',
    'kk': '🇰🇿',
    'mk': '🇲🇰',
    'mn': '🇲🇳',
    'sr': '🇷🇸',
    'ka': '🇬🇪',
    'hy': '🇦🇲',
    'he': '🇮🇱',
    'ur': '🇵🇰',
    'fa': '🇮🇷',
    'am': '🇪🇹',
    'ne': '🇳🇵',
    'bn': '🇧🇩',
    'si': '🇱🇰',
    'lo': '🇱🇦',
    'my': '🇲🇲',
    'km': '🇰🇭',
  };

  static const _flagOverridesByLanguageTag = {
    'zh-Hant': '🇹🇼',
  };

  static const _nameOverridesByLanguageTag = {
    'fil': 'Filipino',
    'zh-Hant': '繁體中文',
  };

  String _localeFlag(Locale locale) {
    return _flagOverridesByLanguageTag[locale.toLanguageTag()] ??
        _flagsByLanguageCode[locale.languageCode] ??
        '🏳️';
  }
}
