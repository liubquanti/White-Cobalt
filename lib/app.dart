import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

import 'controllers/settings_controller.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

class CobaltApp extends StatelessWidget {
  const CobaltApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White Cobalt',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...context.localizationDelegates,
        const LocaleNamesLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.dark,
      home: HomeScreen(settings: settings),
    );
  }
}
