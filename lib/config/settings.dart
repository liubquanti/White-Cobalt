class AppSettings {
  bool useLocalProcessing;
  String downloadDir;
  String downloadMode;
  bool disableMetadata;
  bool shareLinks;
  bool shareCopyToClipboard;

  AppSettings({
    this.useLocalProcessing = true,
    this.downloadDir = '/storage/emulated/0/Download/Cobalt',
    this.downloadMode = 'auto',
    this.disableMetadata = false,
    this.shareLinks = false,
    this.shareCopyToClipboard = false,
  });

  Map<String, dynamic> toJson() => {
    'useLocalProcessing': useLocalProcessing,
    'downloadDir': downloadDir,
    'downloadMode': downloadMode,
    'disableMetadata': disableMetadata,
    'shareLinks': shareLinks,
    'shareCopyToClipboard': shareCopyToClipboard,
  };
  
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useLocalProcessing: json['useLocalProcessing'] ?? true,
      downloadDir: json['downloadDir'] ?? '/storage/emulated/0/Download/Cobalt',
      downloadMode: json['downloadMode'] ?? 'auto',
      disableMetadata: json['disableMetadata'] ?? false,
      shareLinks: json['shareLinks'] ?? false,
      shareCopyToClipboard: json['shareCopyToClipboard'] ?? false,
    );
  }
}