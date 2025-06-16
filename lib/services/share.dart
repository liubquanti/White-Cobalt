import 'package:flutter/services.dart';

class NativeShare {
  static const platform = MethodChannel('com.whitecobalt.native_share');
  
  static Future<void> shareText(String text) async {
    try {
      await platform.invokeMethod('shareText', {'text': text});
    } on PlatformException catch (e) {
      print("Failed to share text: ${e.message}");
    }
  }
}