class AppSettings {
  bool useLocalProcessing;
  String downloadDir;
  String downloadMode;
  bool disableMetadata;
  bool autoDownloadFromShare;
  bool shareLinks;
  bool shareCopyToClipboard;
  bool showShareButton;
  String audioBitrate;
  String audioFormat;
  String videoQuality;
  bool showChangelogs;
  bool showBanner;

  AppSettings({
    this.useLocalProcessing = true,
    this.downloadDir = '/storage/emulated/0/Download/Cobalt',
    this.downloadMode = 'auto',
    this.disableMetadata = false,
    this.autoDownloadFromShare = true,
    this.shareLinks = false,
    this.shareCopyToClipboard = false,
    this.showShareButton = true,
    this.audioBitrate = '320',
    this.audioFormat = 'best',
    this.videoQuality = 'max',
    this.showChangelogs = true,
    this.showBanner = true,
  });

  Map<String, dynamic> toJson() => {
    'useLocalProcessing': useLocalProcessing,
    'downloadDir': downloadDir,
    'downloadMode': downloadMode,
    'disableMetadata': disableMetadata,
    'autoDownloadFromShare': autoDownloadFromShare,
    'shareLinks': shareLinks,
    'shareCopyToClipboard': shareCopyToClipboard,
    'showShareButton': showShareButton,
    'audioBitrate': audioBitrate,
    'audioFormat': audioFormat,
    'videoQuality': videoQuality,
    'showChangelogs': showChangelogs,
    'showBanner': showBanner,
  };
  
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useLocalProcessing: json['useLocalProcessing'] ?? true,
      downloadDir: json['downloadDir'] ?? '/storage/emulated/0/Download/Cobalt',
      downloadMode: json['downloadMode'] ?? 'auto',
      disableMetadata: json['disableMetadata'] ?? false,
      autoDownloadFromShare: json['autoDownloadFromShare'] ?? true,
      shareLinks: json['shareLinks'] ?? false,
      shareCopyToClipboard: json['shareCopyToClipboard'] ?? false,
      showShareButton: json['showShareButton'] ?? true,
      audioBitrate: json['audioBitrate'] ?? '320',
      audioFormat: json['audioFormat'] ?? 'best',
      videoQuality: json['videoQuality'] ?? 'max',
      showChangelogs: json['showChangelogs'] ?? true,
      showBanner: json['showBanner'] ?? true,
    );
  }
}