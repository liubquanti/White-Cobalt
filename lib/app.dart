import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home.dart';

class CobaltApp extends StatelessWidget {
  const CobaltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White Cobalt',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'NotoSansMono',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      home: const CobaltHomePage(),
    );
  }
}