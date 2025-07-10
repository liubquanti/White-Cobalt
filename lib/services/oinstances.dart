import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/oinstance.dart';

class OfficialServersService {
  static const String apiUrl = 'https://raw.githubusercontent.com/liubquanti/White-Cobalt/refs/heads/main/files/servers.json';
  
  static Future<List<OfficialServer>> fetchOfficialServers() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'whcobalt/5.0.1',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((serverJson) => OfficialServer.fromJson(serverJson))
            .toList();
      } else {
        throw Exception('Failed to load official servers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load official servers: $e');
    }
  }
}