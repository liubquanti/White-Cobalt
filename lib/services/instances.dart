import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/instance.dart';

class InstancesService {
  static const String apiUrl = 'http://instances.cobalt.best/api/instances.json';
  
  static Future<List<CobaltInstance>> fetchInstances() async {
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
            .map((instanceJson) => CobaltInstance.fromJson(instanceJson))
            .toList();
      } else {
        throw Exception('Failed to load instances: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load instances: $e');
    }
  }
}