import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'app.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  print('Download task ($id) is in status ($status) and progress ($progress)');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light, 
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  await FlutterDownloader.initialize(
    debug: false
  );
  
  FlutterDownloader.registerCallback(downloadCallback);
  
  runApp(const CobaltApp());
}