import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../utils/logger.dart';

/// Single owner of [AppSettings]. Every screen reads and writes settings
/// through this object, so they can no longer drift out of sync (the home
/// screen, settings screen and advanced screen each used to keep their own
/// copy).
class SettingsController extends ChangeNotifier {
  SettingsController._(this._value);

  static const _prefsKey = 'app_settings';

  AppSettings _value;
  AppSettings get value => _value;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    var settings = const AppSettings();
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        logDebug('Corrupt settings, using defaults: $e');
      }
    }
    return SettingsController._(settings);
  }

  /// `settings.update((s) => s.copyWith(shareLinks: true))`
  Future<void> update(AppSettings Function(AppSettings current) change) async {
    _value = change(_value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_value.toJson()));
  }
}
