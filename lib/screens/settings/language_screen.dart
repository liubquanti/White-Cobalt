import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/app_locales.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/svg_icon.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// Supported locales matching the system's preferred languages, in the
  /// OS priority order.
  List<Locale> _deviceLocales(List<Locale> supported) {
    final matched = <Locale>[];
    for (final system in WidgetsBinding.instance.platformDispatcher.locales) {
      for (final locale in supported) {
        if (matched.contains(locale) || locale.languageCode != system.languageCode) continue;
        if (locale.scriptCode != null && system.scriptCode != null && locale.scriptCode != system.scriptCode) {
          continue;
        }
        matched.add(locale);
        break;
      }
    }
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final supported = context.supportedLocales;
    final device = _deviceLocales(supported);
    final others = supported.where((l) => !device.contains(l)).toList()
      ..sort((a, b) => AppLocales.nativeName(a).toLowerCase().compareTo(AppLocales.nativeName(b).toLowerCase()));

    Widget tile(Locale locale) => _LanguageTile(
          locale: locale,
          selected: context.locale == locale,
          onTap: () => context.setLocale(locale),
        );

    return AppScaffold(
      title: LocaleKeys.ChangeLanguage.tr(),
      body: PageScrollView(
        top: AppSpacing.gap,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (device.isNotEmpty) ...[
            ...separated([for (final l in device) tile(l)]),
            const SizedBox(height: AppSpacing.gap),
            const Divider(),
            const SizedBox(height: AppSpacing.gap),
          ],
          ...separated([for (final l in others) tile(l)]),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.locale, required this.selected, required this.onTap});

  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Text(AppLocales.flag(locale), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(AppLocales.nativeName(locale), style: AppTextStyles.tileTitle)),
          if (selected) const SvgIcon(AppIcons.check),
        ],
      ),
    );
  }
}
