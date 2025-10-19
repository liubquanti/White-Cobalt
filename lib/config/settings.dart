class AppSettings {
  bool useLocalProcessing;
  String downloadDir;
  String downloadMode;
  bool disableMetadata;
  bool shareLinks;
  bool shareCopyToClipboard;
  String audioBitrate;
  String audioFormat;
  String videoQuality;
  bool showChangelogs;

  AppSettings({
    this.useLocalProcessing = true,
    this.downloadDir = '/storage/emulated/0/Download/Cobalt',
    this.downloadMode = 'auto',
    this.disableMetadata = false,
    this.shareLinks = false,
    this.shareCopyToClipboard = false,
    this.audioBitrate = '320',
    this.audioFormat = 'best',
    this.videoQuality = 'max',
    this.showChangelogs = true,
  });

  Map<String, dynamic> toJson() => {
    'useLocalProcessing': useLocalProcessing,
    'downloadDir': downloadDir,
    'downloadMode': downloadMode,
    'disableMetadata': disableMetadata,
    'shareLinks': shareLinks,
    'shareCopyToClipboard': shareCopyToClipboard,
    'audioBitrate': audioBitrate,
    'audioFormat': audioFormat,
    'videoQuality': videoQuality,
    'showChangelogs': showChangelogs,
  };
  
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useLocalProcessing: json['useLocalProcessing'] ?? true,
      downloadDir: json['downloadDir'] ?? '/storage/emulated/0/Download/Cobalt',
      downloadMode: json['downloadMode'] ?? 'auto',
      disableMetadata: json['disableMetadata'] ?? false,
      shareLinks: json['shareLinks'] ?? false,
      shareCopyToClipboard: json['shareCopyToClipboard'] ?? false,
      audioBitrate: json['audioBitrate'] ?? '320',
      audioFormat: json['audioFormat'] ?? 'best',
      videoQuality: json['videoQuality'] ?? 'max',
      showChangelogs: json['showChangelogs'] ?? true,
    );
  }
}