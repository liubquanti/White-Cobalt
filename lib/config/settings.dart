class AppSettings {
  bool useLocalProcessing;
  String downloadDir;
  String downloadMode;
  bool disableMetadata;

  AppSettings({
    this.useLocalProcessing = true,
    this.downloadDir = '/storage/emulated/0/Download/Cobalt',
    this.downloadMode = 'auto',
    this.disableMetadata = false,
  });

  Map<String, dynamic> toJson() => {
    'useLocalProcessing': useLocalProcessing,
    'downloadDir': downloadDir,
    'downloadMode': downloadMode,
    'disableMetadata': disableMetadata,
  };
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useLocalProcessing: json['useLocalProcessing'] ?? true,
      downloadDir: json['downloadDir'] ?? '/storage/emulated/0/Download/Cobalt',
      downloadMode: json['downloadMode'] ?? 'auto',
      disableMetadata: json['disableMetadata'] ?? false,
    );
  }
}