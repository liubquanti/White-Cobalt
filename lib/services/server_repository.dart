import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_config.dart';
import '../utils/logger.dart';

class StoredServers {
  const StoredServers({required this.servers, required this.selectedUrl, required this.isFirstLaunch});

  final List<ServerConfig> servers;
  final String? selectedUrl;
  final bool isFirstLaunch;
}

/// Persists the saved server list. Server metadata goes to SharedPreferences;
/// API keys go to secure storage only.
class ServerRepository {
  static const _serversKey = 'servers_config';
  static const _selectedUrlKey = 'selected_server_url';
  static const _legacySelectedIndexKey = 'selected_server_index';
  static const _initializedKey = 'app_initialized';
  static const _apiKeyPrefix = 'api_key::';

  static const _secure = FlutterSecureStorage();

  Future<StoredServers> load() async {
    final prefs = await SharedPreferences.getInstance();
    final servers = <ServerConfig>[];
    var hasPlaintextKeys = false;

    for (final raw in prefs.getStringList(_serversKey) ?? const <String>[]) {
      try {
        final server = ServerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (server.hasApiKey) {
          hasPlaintextKeys = true;
          servers.add(server);
        } else {
          final key = await _secure.read(key: '$_apiKeyPrefix${server.url}');
          servers.add(key == null ? server : server.copyWith(apiKey: key));
        }
      } catch (e) {
        logDebug('Skipping corrupt server entry: $e');
      }
    }

    // Migrate keys saved in plaintext by old versions into secure storage.
    if (hasPlaintextKeys) await saveServers(servers);

    // The selection used to be stored as an index, which went stale (and
    // crashed on start-up with a RangeError) after deleting an earlier
    // server. It is now stored by URL; translate the old value once.
    var selectedUrl = prefs.getString(_selectedUrlKey);
    if (selectedUrl == null) {
      final index = prefs.getInt(_legacySelectedIndexKey);
      if (index != null && index >= 0 && index < servers.length) selectedUrl = servers[index].url;
      await prefs.remove(_legacySelectedIndexKey);
    }

    return StoredServers(
      servers: servers,
      selectedUrl: selectedUrl,
      isFirstLaunch: !prefs.containsKey(_initializedKey),
    );
  }

  Future<void> markInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initializedKey, true);
  }

  Future<void> saveSelected(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null) {
      await prefs.remove(_selectedUrlKey);
    } else {
      await prefs.setString(_selectedUrlKey, url);
    }
  }

  Future<void> saveServers(List<ServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_serversKey, [for (final s in servers) jsonEncode(s.toJson())]);

    final urls = <String>{};
    for (final server in servers) {
      urls.add(server.url);
      final key = '$_apiKeyPrefix${server.url}';
      if (server.hasApiKey) {
        await _secure.write(key: key, value: server.apiKey);
      } else {
        await _secure.delete(key: key);
      }
    }

    // Drop keys of servers that were removed.
    final stored = await _secure.readAll();
    for (final key in stored.keys) {
      if (key.startsWith(_apiKeyPrefix) && !urls.contains(key.substring(_apiKeyPrefix.length))) {
        await _secure.delete(key: key);
      }
    }
  }
}
