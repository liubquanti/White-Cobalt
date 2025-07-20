class CobaltInstance {
  final String api;
  final String? frontend;
  final bool nodomain;
  final OnlineStatus online;
  final String protocol;
  final int score;
  final Map<String, dynamic> services;
  final int trust;
  final String? branch;
  final String? commit;
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
    this.branch,
    this.commit,
    this.cors,
    this.name,
    this.version,
  });

  String get apiUrl => '$protocol://$api';
  
  int get servicesCount => services.entries
    .where((entry) => entry.value == true)
    .length;
    
  bool get isOnline => online.api;

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
      branch: (json['git']?['branch'] ?? json['branch']) as String?,
      commit: (json['git']?['commit'] ?? json['commit']) as String?,
      cors: (json['info']?['cors'] ?? json['cors']) as bool?,
      name: json['name'] as String?,
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