import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pinstance.dart';

class PartnerServersService {
  static const String apiUrl = 'https://raw.githubusercontent.com/liubquanti/White-Cobalt/refs/heads/main/files/partners.json';

  static Future<List<PartnerServer>> fetchPartnerServers() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((serverJson) => PartnerServer.fromJson(serverJson as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load partner servers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load partner servers: $e');
    }
  }
}
