class ServerConfig {
  final String url;
  final String? apiKey;
  final String? name;
  final bool isOfficial;

  ServerConfig(
    this.url,
    this.apiKey, {
    this.name,
    this.isOfficial = false,
  });

  // apiKey is intentionally excluded here: it is persisted separately in
  // secure storage, never in this plaintext JSON blob (see
  // _CobaltHomePageState._saveServers/_hydrateApiKeysFromSecureStorage).
  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'isOfficial': isOfficial,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      json['url'] as String,
      // Only present when reading data saved before secure storage was
      // introduced; callers migrate it out on load.
      json['apiKey'] as String?,
      name: json['name'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? false,
    );
  }
}