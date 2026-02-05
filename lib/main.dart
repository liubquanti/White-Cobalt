import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:white_cobalt/generated/codegen_loader.g.dart';

import 'app.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  print('Download task ($id) is in status ($status) and progress ($progress)');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e) {
    // Fallback: missing .env should not block app startup.
  }

  await FlutterDownloader.initialize(debug: false);

  FlutterDownloader.registerCallback(downloadCallback);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
        Locale('de'),
        Locale('fr'),
        Locale('hi'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const CodegenLoader(),
      child: const CobaltApp(),
    ),
  );
}
