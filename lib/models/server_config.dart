/// A cobalt API instance the user has saved.
class ServerConfig {
  const ServerConfig({
    required this.url,
    this.apiKey,
    this.name,
    this.isOfficial = false,
  });

  final String url;
  final String? apiKey;
  final String? name;
  final bool isOfficial;

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  /// Official servers show their friendly name, others their URL.
  String get displayLabel {
    final trimmed = name?.trim();
    return isOfficial && trimmed != null && trimmed.isNotEmpty ? trimmed : url;
  }

  ServerConfig copyWith({String? apiKey, String? name, bool? isOfficial}) {
    return ServerConfig(
      url: url,
      apiKey: apiKey ?? this.apiKey,
      name: name ?? this.name,
      isOfficial: isOfficial ?? this.isOfficial,
    );
  }

  /// The API key is intentionally excluded: it lives in secure storage, never
  /// in this plaintext SharedPreferences blob (see ServerRepository).
  Map<String, dynamic> toJson() => {'url': url, 'name': name, 'isOfficial': isOfficial};

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      url: json['url'] as String,
      // Only present in data saved before secure storage was introduced;
      // ServerRepository migrates it out on load.
      apiKey: json['apiKey'] as String?,
      name: json['name'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? false,
    );
  }

  /// Turns user input like `api.example.com/` into `https://api.example.com`.
  /// Returns null when the input cannot be a valid http(s) URL.
  static String? normalizeUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'https://$value';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
      return null;
    }
    return value;
  }
}
