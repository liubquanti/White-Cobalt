import 'package:flutter/services.dart';

import '../utils/logger.dart';

class DeviceStorageInfo {
  static const platform = MethodChannel('com.whitecobalt.storage/info');

  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final result = await platform.invokeMethod('getStorageStats');
      return {
        'total': result['total'] as int,
        'free': result['free'] as int,
        'used': result['used'] as int,
      };
    } on PlatformException catch (e) {
      logDebug('Failed to get storage stats: ${e.message}');
      return {
        'total': 0,
        'free': 0,
        'used': 0,
      };
    }
  }
}

class ServiceStorage {
  final String serviceName;
  final int size;

  ServiceStorage(this.serviceName, this.size);
}