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
    final bool isOnline = json['online'] as bool? ?? false;
    final Map<String, dynamic> gitInfo = json['git'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> infoData = json['info'] as Map<String, dynamic>? ?? {};
    
    return CobaltInstance(
      api: json['api'] as String,
      frontend: json['frontend'] as String?,
      nodomain: false,
      online: OnlineStatus(
        api: isOnline,
        frontend: isOnline && json['frontend'] != null,
      ),
      protocol: json['protocol'] as String,
      score: json['score'] as int? ?? 0,
      services: json['services'] as Map<String, dynamic>? ?? {},
      trust: 100,
      branch: gitInfo['branch'] as String?,
      commit: gitInfo['commit'] as String?,
      cors: infoData['cors'] as bool?,
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