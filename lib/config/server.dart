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

  Map<String, dynamic> toJson() => {
    'url': url,
    'apiKey': apiKey,
    'name': name,
    'isOfficial': isOfficial,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      json['url'] as String,
      json['apiKey'] as String?,
      name: json['name'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? false,
    );
  }
}