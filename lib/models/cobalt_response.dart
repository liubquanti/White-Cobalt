/// `GET /` of a cobalt instance.
class ServerInfo {
  const ServerInfo({required this.version, required this.servicesCount});

  final String version;
  final int servicesCount;

  /// Returns null when the payload is not a cobalt server info document.
  static ServerInfo? tryParse(Object? json) {
    if (json is! Map) return null;
    final cobalt = json['cobalt'];
    if (cobalt is! Map) return null;
    final version = cobalt['version'];
    final services = cobalt['services'];
    final count = services is List ? services.length : (services is Map ? services.length : null);
    if (version == null || count == null) return null;
    return ServerInfo(version: version.toString(), servicesCount: count);
  }
}

enum CobaltStatus { tunnel, redirect, localProcessing, picker, error, unknown }

/// Parsed `POST /` response of the cobalt API. Every field is read
/// defensively — the server is third-party and may be malicious or buggy.
class CobaltResponse {
  const CobaltResponse({
    required this.status,
    this.rawStatus,
    this.url,
    this.filename,
    this.service,
    this.processingType,
    this.picker = const [],
    this.errorCode,
    this.errorMessage,
  });

  final CobaltStatus status;
  final String? rawStatus;

  /// Direct link for tunnel/redirect, first tunnel for local-processing.
  final String? url;
  final String? filename;
  final String? service;
  final String? processingType;
  final List<PickerItem> picker;
  final String? errorCode;
  final String? errorMessage;

  bool get isAuthKeyMissing => errorCode == 'error.api.auth.key.missing';

  factory CobaltResponse.fromJson(Object? json) {
    if (json is! Map) return const CobaltResponse(status: CobaltStatus.unknown);
    final raw = json['status']?.toString();
    final service = json['service']?.toString();

    switch (raw) {
      case 'tunnel':
      case 'redirect':
        return CobaltResponse(
          status: raw == 'tunnel' ? CobaltStatus.tunnel : CobaltStatus.redirect,
          rawStatus: raw,
          url: json['url']?.toString(),
          filename: json['filename']?.toString(),
          service: service,
        );
      case 'local-processing':
        final tunnel = json['tunnel'];
        final output = json['output'];
        return CobaltResponse(
          status: CobaltStatus.localProcessing,
          rawStatus: raw,
          url: tunnel is List && tunnel.isNotEmpty ? tunnel.first?.toString() : null,
          filename: output is Map ? output['filename']?.toString() : null,
          processingType: json['type']?.toString(),
          service: service,
        );
      case 'picker':
        final items = json['picker'];
        return CobaltResponse(
          status: CobaltStatus.picker,
          rawStatus: raw,
          service: service,
          picker: items is List
              ? items.whereType<Map>().map(PickerItem.fromJson).whereType<PickerItem>().toList()
              : const [],
        );
      case 'error':
        final error = json['error'];
        return CobaltResponse(
          status: CobaltStatus.error,
          rawStatus: raw,
          errorCode: error is Map ? error['code']?.toString() : error?.toString(),
          errorMessage: error is Map ? error['message']?.toString() : null,
        );
      default:
        return CobaltResponse(status: CobaltStatus.unknown, rawStatus: raw);
    }
  }
}

class PickerItem {
  const PickerItem({required this.type, required this.url, this.thumb});

  /// `photo`, `video` or `gif`.
  final String type;
  final String url;
  final String? thumb;

  String get extension => switch (type) {
        'photo' => '.jpg',
        'gif' => '.gif',
        _ => '.mp4',
      };

  static PickerItem? fromJson(Map json) {
    final url = json['url']?.toString();
    if (url == null || url.isEmpty) return null;
    return PickerItem(
      type: json['type']?.toString() ?? 'video',
      url: url,
      thumb: json['thumb']?.toString(),
    );
  }
}
