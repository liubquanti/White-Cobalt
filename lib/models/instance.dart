class CobaltInstance {
  final String api;
  final String? frontend;
  final bool nodomain;
  final OnlineStatus online;
  final String protocol;
  final int score;
  final Map<String, dynamic> services;
  final int trust;
  final String? status;
  final String? branch;
  final String? commit;
  final bool? auth;
  final bool? cors;
  final String? name;
  final String? version;

  CobaltInstance({
    required this.api,
    this.frontend,
    required this.nodomain,
    required this.online,
    required this.protocol,
    required this.score,
    required this.services,
    required this.trust,
    this.status,
    this.branch,
    this.commit,
    this.auth,
    this.cors,
    this.name,
    this.version,
  });

  String get apiUrl => '$protocol://$api';
  
  int get servicesCount => services.entries
      .where(
        (entry) =>
            entry.value == true && entry.key.toString().toLowerCase() != 'frontend',
      )
      .length;
    
  bool get isOnline => online.api;

  bool get requiresAuth => auth == true;

  factory CobaltInstance.fromJson(Map<String, dynamic> json) {
    OnlineStatus onlineStatus;
    if (json['online'] is bool) {
      onlineStatus = OnlineStatus(api: json['online'] as bool, frontend: false);
    } else if (json['online'] is Map<String, dynamic>) {
      onlineStatus = OnlineStatus.fromJson(json['online'] as Map<String, dynamic>);
    } else {
      onlineStatus = OnlineStatus(api: false, frontend: false);
    }

    return CobaltInstance(
      api: json['api'] as String,
      frontend: json['frontend'] as String?,
      nodomain: json['nodomain'] as bool? ?? false,
      online: onlineStatus,
      protocol: json['protocol'] as String,
      score: json['score'] as int? ?? 0,
      services: json['services'] as Map<String, dynamic>? ?? {},
      trust: json['trust'] as int? ?? 0,
      status: json['status'] as String?,
      branch: (json['git']?['branch'] ?? json['branch']) as String?,
      commit: (json['git']?['commit'] ?? json['commit']) as String?,
      auth: (json['info']?['auth'] ?? json['auth']) as bool?,
      cors: (json['info']?['cors'] ?? json['cors']) as bool?,
      name: json['name'] as String?,
      version: json['version'] as String?,
    );
  }

  factory CobaltInstance.fromHyperJson(Map<String, dynamic> json) {
    final rawTests = json['tests'];
    final Map<String, dynamic> services = {};
    int successCount = 0;
    int totalCount = 0;
    bool frontendOnline = false;

    if (rawTests is Map<String, dynamic>) {
      rawTests.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final status = value['status'];
          if (status is bool) {
            final keyString = key.toString();
            services[keyString] = status;
            if (keyString.toLowerCase() == 'frontend') {
              frontendOnline = status;
            } else {
              totalCount++;
              if (status) {
                successCount++;
              }
            }
          }
        }
      });
    }

    final bool apiOnline = json['online'] == true;
    final int computedScore;
    if (totalCount > 0) {
      computedScore = ((successCount / totalCount) * 100).round();
    } else {
      computedScore = apiOnline ? 100 : 0;
    }

    return CobaltInstance(
      api: json['api'] as String,
      frontend: json['frontend'] as String?,
      nodomain: false,
      online: OnlineStatus(
        api: apiOnline,
        frontend: frontendOnline,
      ),
      protocol: json['protocol'] as String? ?? 'https',
      score: computedScore,
      services: services,
      trust: 0,
      status: null,
      branch: null,
      commit: null,
      auth: null,
      cors: null,
      name: null,
      version: json['version'] as String?,
    );
  }
}

class OnlineStatus {
  final bool api;
  final bool frontend;

  OnlineStatus({
    required this.api,
    required this.frontend,
  });

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      api: json['api'] as bool,
      frontend: json['frontend'] as bool,
    );
  }
}