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
        Locale('zh'),
        Locale('es'),
        Locale('pt'),
        Locale('ru'),
        Locale('ja'),
        Locale('it'),
        Locale('nl'),
        Locale('pl'),
        Locale('cs'),
        Locale('sl'),
        Locale('hu'),
        Locale('ro'),
        Locale('bg'),
        Locale('el'),
        Locale('tr'),
        Locale('ar'),
        Locale('th'),
        Locale('sv'),
        Locale('ko'),
        Locale('af'),
        Locale('az'),
        Locale('id'),
        Locale('ms'),
        Locale('bs'),
        Locale('ca'),
        Locale('da'),
        Locale('et'),
        Locale('fil'),
        Locale('hr'),
        Locale('zu'),
        Locale('is'),
        Locale('sw'),
        Locale('lv'),
        Locale('lt'),
        Locale('no'),
        Locale('uz'),
        Locale('sq'),
        Locale('sk'),
        Locale('fi'),
        Locale('vi'),
        Locale('ky'),
        Locale('kk'),
        Locale('mk'),
        Locale('mn'),
        Locale('sr'),
        Locale('ka'),
        Locale('hy'),
        Locale('he'),
        Locale('ur'),
        Locale('fa'),
        Locale('am'),
        Locale('ne'),
        Locale('bn'),
        Locale('si'),
        Locale('lo'),
        Locale('my'),
        Locale('km'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const CodegenLoader(),
      child: const CobaltApp(),
    ),
  );
}
