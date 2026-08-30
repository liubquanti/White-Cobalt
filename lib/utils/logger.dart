import 'package:flutter/foundation.dart';

/// Debug-only logging: compiled out of release builds so request/response
/// bodies, download URLs and other diagnostic details are never written to
/// the device log (logcat) on a production install.
void logDebug(Object? message) {
  if (kDebugMode) {
    debugPrint(message.toString());
  }
}
