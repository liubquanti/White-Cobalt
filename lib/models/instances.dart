/// Public cobalt instance reported by one of the community trackers.
class CobaltInstance {
  const CobaltInstance({
    required this.api,
    required this.protocol,
    required this.isOnline,
    required this.score,
    required this.services,
    this.frontend,
    this.auth,
    this.version,
  });

  final String api;
  final String protocol;
  final bool isOnline;
  final int score;
  final Map<String, dynamic> services;
  final String? frontend;
  final bool? auth;
  final String? version;

  String get apiUrl => '$protocol://$api';

  String? get frontendUrl => _frontendUrl(protocol, frontend);

  int get servicesCount => services.entries
      .where((e) => e.value == true && e.key.toLowerCase() != 'frontend')
      .length;

  /// Online instances first, then by score (descending).
  static int byAvailability(CobaltInstance a, CobaltInstance b) {
    if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
    return b.score.compareTo(a.score);
  }

  /// instances.cobalt.best format.
  factory CobaltInstance.fromKwiatJson(Map<String, dynamic> json) {
    final online = json['online'];
    final isOnline = online is bool
        ? online
        : online is Map
            ? online['api'] == true
            : false;
    final git = json['git'];
    final info = json['info'];
    return CobaltInstance(
      api: json['api'] as String,
      protocol: json['protocol'] as String? ?? 'https',
      isOnline: isOnline,
      score: (json['score'] as num?)?.round() ?? 0,
      services: json['services'] is Map<String, dynamic> ? json['services'] as Map<String, dynamic> : const {},
      frontend: json['frontend'] as String?,
      auth: (info is Map ? info['auth'] : null) as bool? ?? json['auth'] as bool?,
      version: json['version'] as String? ?? (git is Map ? git['version'] as String? : null),
    );
  }

  /// cobalt.directory format: score is the share of passing service tests.
  factory CobaltInstance.fromHyperJson(Map<String, dynamic> json) {
    final services = <String, dynamic>{};
    var passed = 0;
    var total = 0;
    final tests = json['tests'];
    if (tests is Map<String, dynamic>) {
      tests.forEach((key, value) {
        final status = value is Map ? value['status'] : null;
        if (status is! bool) return;
        services[key] = status;
        if (key.toLowerCase() == 'frontend') return;
        total++;
        if (status) passed++;
      });
    }
    final isOnline = json['online'] == true;
    return CobaltInstance(
      api: json['api'] as String,
      protocol: json['protocol'] as String? ?? 'https',
      isOnline: isOnline,
      score: total > 0 ? (passed / total * 100).round() : (isOnline ? 100 : 0),
      services: services,
      frontend: json['frontend'] as String?,
      version: json['version'] as String?,
    );
  }
}

/// Server recommended by White Cobalt itself (files/servers.json).
class OfficialServer {
  const OfficialServer({
    required this.api,
    required this.protocol,
    required this.reason,
    required this.logo,
    this.frontend,
    this.name,
    this.auth,
    this.autoAdd = false,
  });

  final String api;
  final String protocol;
  final String reason;
  final String logo;
  final String? frontend;
  final String? name;
  final bool? auth;
  final bool autoAdd;

  String get apiUrl => '$protocol://$api';

  String? get frontendUrl => _frontendUrl(protocol, frontend);

  String get title {
    final trimmed = name?.trim();
    return trimmed != null && trimmed.isNotEmpty ? trimmed : api;
  }

  factory OfficialServer.fromJson(Map<String, dynamic> json) {
    return OfficialServer(
      api: json['api'] as String,
      protocol: json['protocol'] as String? ?? 'https',
      reason: json['reason'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      frontend: json['frontend'] as String?,
      name: json['name'] as String?,
      auth: json['auth'] as bool?,
      autoAdd: json['autoadd'] as bool? ?? false,
    );
  }
}

String? _frontendUrl(String protocol, String? frontend) {
  if (frontend == null || frontend.isEmpty || frontend == 'None') return null;
  return '$protocol://$frontend';
}
