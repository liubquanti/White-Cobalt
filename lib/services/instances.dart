import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/instance.dart';

class InstancesService {
  static const String apiUrl = 'http://instances.cobalt.best/api/instances.json';
  static String? _userAgent;
  
  static Future<String> _getUserAgent() async {
    if (_userAgent == null) {
      final packageInfo = await PackageInfo.fromPlatform();
      _userAgent = 'liubquanti.white.cobalt/${packageInfo.version}';
    }
    return _userAgent!;
  }
  
  static Future<List<CobaltInstance>> fetchInstances() async {
    try {
      final userAgent = await _getUserAgent();
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': userAgent,
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