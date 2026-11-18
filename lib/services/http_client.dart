import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Non-2xx HTTP response.
class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode, [this.body]);

  final int statusCode;
  final String? body;

  @override
  String toString() => 'HTTP $statusCode';
}

/// Thin wrapper over one shared [http.Client].
///
/// Every request gets a timeout (previously a dead server could leave the UI
/// spinning forever) and an identifying User-Agent.
abstract final class AppHttp {
  static final http.Client _client = http.Client();
  static const timeout = Duration(seconds: 20);

  static String? _userAgent;

  static Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    _userAgent ??= 'liubquanti.white.cobalt/${(await PackageInfo.fromPlatform()).version}';
    return {'User-Agent': _userAgent!, ...?extra};
  }

  static Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _client.get(Uri.parse(url), headers: await _headers(headers)).timeout(timeout);
  }

  static Future<http.Response> post(
    String url, {
    required Map<String, String> headers,
    required Object body,
  }) async {
    // Cobalt may need a while to resolve some services; allow more time.
    return _client
        .post(Uri.parse(url), headers: await _headers(headers), body: body)
        .timeout(timeout * 2);
  }

  /// GET and decode JSON; throws [HttpStatusException] on non-200.
  static Future<Object?> getJson(String url, {Map<String, String>? headers}) async {
    final response = await get(url, headers: headers);
    if (response.statusCode != 200) throw HttpStatusException(response.statusCode, response.body);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// GET as text; throws [HttpStatusException] on non-200.
  static Future<String> getText(String url) async {
    final response = await get(url);
    if (response.statusCode != 200) throw HttpStatusException(response.statusCode);
    return utf8.decode(response.bodyBytes);
  }
}
