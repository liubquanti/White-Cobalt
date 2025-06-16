class ServerConfig {
  final String url;
  final String? apiKey;

  ServerConfig(this.url, this.apiKey);

  Map<String, dynamic> toJson() => {
    'url': url,
    'apiKey': apiKey,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      json['url'] as String,
      json['apiKey'] as String?,
    );
  }
}