import 'package:flutter/services.dart';

import '../utils/logger.dart';

class NativeShare {
  static const platform = MethodChannel('com.whitecobalt.native_share');

  static Future<void> shareText(String text) async {
    try {
      await platform.invokeMethod('shareText', {'text': text});
    } on PlatformException catch (e) {
      logDebug("Failed to share text: ${e.message}");
    }
  }
}