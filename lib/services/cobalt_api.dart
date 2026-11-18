import 'dart:convert';

import '../models/app_settings.dart';
import '../models/cobalt_response.dart';
import '../models/server_config.dart';
import '../utils/logger.dart';
import 'http_client.dart';

/// The server answered, but it is not a cobalt instance.
class NotCobaltServerException implements Exception {
  const NotCobaltServerException();
}

/// Talks to a single cobalt API instance.
abstract final class CobaltApi {
  static Future<ServerInfo> fetchInfo(String serverUrl) async {
    final json = await AppHttp.getJson(serverUrl);
    final info = ServerInfo.tryParse(json);
    if (info == null) throw const NotCobaltServerException();
    return info;
  }

  /// Requests a download for [mediaUrl]. Error responses (any status code)
  /// are returned as [CobaltStatus.error]; only transport failures and
  /// non-JSON error bodies throw.
  static Future<CobaltResponse> request({
    required ServerConfig server,
    required String mediaUrl,
    required AppSettings settings,
  }) async {
    final payload = {
      'url': mediaUrl,
      'videoQuality': settings.videoQuality,
      'audioFormat': settings.audioFormat,
      'audioBitrate': settings.audioBitrate,
      'filenameStyle': 'classic',
      'downloadMode': settings.downloadMode,
      'localProcessing': settings.useLocalProcessing,
      'disableMetadata': settings.disableMetadata,
      if (settings.shareLinks) 'alwaysProxy': true,
    };

    final response = await AppHttp.post(
      server.url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (server.hasApiKey) 'Authorization': 'Api-Key ${server.apiKey}',
      },
      body: jsonEncode(payload),
    );
    logDebug('cobalt ${response.statusCode}: ${response.body}');

    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw HttpStatusException(response.statusCode, response.body);
    }
    final parsed = CobaltResponse.fromJson(json);
    if (response.statusCode != 200 && parsed.status != CobaltStatus.error) {
      throw HttpStatusException(response.statusCode, response.body);
    }
    return parsed;
  }

  /// Some self-hosted instances hand out `http://localhost:9000/...` tunnel
  /// links. Point those at the host/port/scheme the user actually reaches
  /// the server on.
  static String resolveMediaUrl(String url, String serverUrl) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.host == 'localhost' || uri.host == '127.0.0.1')) return url;
    final base = Uri.parse(serverUrl);
    return uri.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
  }
}
