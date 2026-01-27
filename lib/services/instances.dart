import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/instance.dart';

class InstancesService {
  static const String kwiatApiUrl = 'http://instances.cobalt.best/instances.json';
  static const String hyperApiUrl = 'https://cobalt.directory/api/tests';
  static String? _userAgent;
  
  static Future<String> _getUserAgent() async {
    if (_userAgent == null) {
      final packageInfo = await PackageInfo.fromPlatform();
      _userAgent = 'liubquanti.white.cobalt/${packageInfo.version}';
    }
    return _userAgent!;
  }
  
  static Future<InstancesResponse> fetchInstances() async {
    final userAgent = await _getUserAgent();
    List<CobaltInstance> kwiat = [];
    List<CobaltInstance> hyper = [];
    Object? lastError;

    try {
      kwiat = await _fetchKwiatInstances(userAgent);
    } catch (e) {
      lastError = e;
    }

    try {
      hyper = await _fetchHyperInstances(userAgent);
    } catch (e) {
      lastError = e;
    }

    final dedupedKwiat = _deduplicateInstances(kwiat);
    final dedupedHyper = _deduplicateInstances(hyper);

    final hasAnyData = dedupedKwiat.isNotEmpty || dedupedHyper.isNotEmpty;

    if (!hasAnyData && lastError != null) {
      throw Exception('Failed to load instances: $lastError');
    }

    return InstancesResponse(
      kwiat: dedupedKwiat,
      hyper: dedupedHyper,
    );
  }

  static Future<List<CobaltInstance>> _fetchKwiatInstances(String userAgent) async {
    final response = await http.get(
      Uri.parse(kwiatApiUrl),
      headers: {
        'User-Agent': userAgent,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load kwiat instances: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format for kwiat instances');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CobaltInstance.fromJson)
        .toList();
  }

  static Future<List<CobaltInstance>> _fetchHyperInstances(String userAgent) async {
    final response = await http.get(
      Uri.parse(hyperApiUrl),
      headers: {
        'User-Agent': userAgent,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load hyper instances: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for hyper instances');
    }

    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Missing data array in hyper instances response');
    }

    final List<CobaltInstance> instances = [];
    for (final entry in data) {
      if (entry is Map<String, dynamic> && entry['api'] is String) {
        instances.add(CobaltInstance.fromHyperJson(entry));
      }
    }

    return instances;
  }

  static List<CobaltInstance> _deduplicateInstances(List<CobaltInstance> instances) {
    final seen = <String>{};
    final List<CobaltInstance> result = [];

    for (final instance in instances) {
      final key = instance.apiUrl.toLowerCase();
      if (seen.add(key)) {
        result.add(instance);
      }
    }

    return result;
  }
}

class InstancesResponse {
  InstancesResponse({
    required this.kwiat,
    required this.hyper,
  });

  final List<CobaltInstance> kwiat;
  final List<CobaltInstance> hyper;
}