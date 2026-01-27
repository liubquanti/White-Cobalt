class OfficialServer {
  final String api;
  final String frontend;
  final String protocol;
  final String reason;
  final String logo;
  final bool? auth;

  OfficialServer({
    required this.api,
    required this.frontend,
    required this.protocol,
    required this.reason,
    required this.logo,
    this.auth,
  });

  String get apiUrl => '$protocol://$api';

  factory OfficialServer.fromJson(Map<String, dynamic> json) {
    return OfficialServer(
      api: json['api'] as String,
      frontend: json['frontend'] as String,
      protocol: json['protocol'] as String,
      reason: json['reason'] as String,
      logo: json['logo'] as String,
      auth: json['auth'] as bool?,
    );
  }
}