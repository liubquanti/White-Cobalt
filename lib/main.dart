import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/app_locales.dart';
import 'controllers/settings_controller.dart';
import 'generated/codegen_loader.g.dart';
import 'services/download_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

  final (_, settings, _) = await (
    EasyLocalization.ensureInitialized(),
    SettingsController.load(),
    DownloadService.initialize(),
  ).wait;

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      fallbackLocale: AppLocales.fallback,
      // Translations are compiled into Dart by CodegenLoader; `path` is
      // required by the API but no JSON assets are read at runtime.
      path: 'assets/translations',
      assetLoader: const CodegenLoader(),
      child: CobaltApp(settings: settings),
    ),
  );
}
