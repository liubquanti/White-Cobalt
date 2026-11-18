import 'package:flutter/services.dart';

import '../models/misc.dart';
import '../utils/logger.dart';

/// All platform-channel calls to MainActivity.kt.
abstract final class NativeBridge {
  static const _share = MethodChannel('com.whitecobalt.share/url');
  static const _storage = MethodChannel('com.whitecobalt.storage/info');
  static const _nativeShare = MethodChannel('com.whitecobalt.native_share');

  /// URL received through Android's share sheet; consumed on read.
  static Future<String?> takeSharedUrl() async {
    try {
      final url = await _share.invokeMethod<String>('getSharedUrl');
      return (url == null || url.trim().isEmpty) ? null : url.trim();
    } on PlatformException catch (e) {
      logDebug('getSharedUrl failed: ${e.message}');
      return null;
    }
  }

  static Future<void> shareText(String text) async {
    try {
      await _nativeShare.invokeMethod('shareText', {'text': text});
    } on PlatformException catch (e) {
      logDebug('shareText failed: ${e.message}');
    }
  }

  static Future<DeviceStorage> storageStats() async {
    try {
      final result = await _storage.invokeMapMethod<String, Object?>('getStorageStats');
      final total = (result?['total'] as num?)?.toInt() ?? 0;
      final free = (result?['free'] as num?)?.toInt() ?? 0;
      return DeviceStorage(total: total, free: free);
    } on PlatformException catch (e) {
      logDebug('getStorageStats failed: ${e.message}');
      return DeviceStorage.empty;
    }
  }
}
