/// User preferences. Immutable — change with [copyWith].
class AppSettings {
  const AppSettings({
    this.useLocalProcessing = true,
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

  static const downloadModes = ['auto', 'audio', 'mute'];
  static const videoQualities = ['max', '4320', '2160', '1440', '1080', '720', '480', '360', '240', '144'];
  static const audioBitrates = ['320', '256', '128', '96', '64', '8'];
  static const audioFormats = ['best', 'mp3', 'ogg', 'wav', 'opus'];

  final bool useLocalProcessing;
  final String downloadMode;
  final bool disableMetadata;
  final bool autoDownloadFromShare;
  final bool shareLinks;
  final bool shareCopyToClipboard;
  final bool showShareButton;
  final String audioBitrate;
  final String audioFormat;
  final String videoQuality;
  final bool showChangelogs;
  final bool showBanner;

  AppSettings copyWith({
    bool? useLocalProcessing,
    String? downloadMode,
    bool? disableMetadata,
    bool? autoDownloadFromShare,
    bool? shareLinks,
    bool? shareCopyToClipboard,
    bool? showShareButton,
    String? audioBitrate,
    String? audioFormat,
    String? videoQuality,
    bool? showChangelogs,
    bool? showBanner,
  }) {
    return AppSettings(
      useLocalProcessing: useLocalProcessing ?? this.useLocalProcessing,
      downloadMode: downloadMode ?? this.downloadMode,
      disableMetadata: disableMetadata ?? this.disableMetadata,
      autoDownloadFromShare: autoDownloadFromShare ?? this.autoDownloadFromShare,
      shareLinks: shareLinks ?? this.shareLinks,
      shareCopyToClipboard: shareCopyToClipboard ?? this.shareCopyToClipboard,
      showShareButton: showShareButton ?? this.showShareButton,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioFormat: audioFormat ?? this.audioFormat,
      videoQuality: videoQuality ?? this.videoQuality,
      showChangelogs: showChangelogs ?? this.showChangelogs,
      showBanner: showBanner ?? this.showBanner,
    );
  }

  Map<String, dynamic> toJson() => {
        'useLocalProcessing': useLocalProcessing,
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

  /// Tolerant of missing/mistyped keys and of values that are no longer
  /// offered (falls back to the default instead of crashing a dropdown).
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    bool b(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    String s(String key, String fallback, List<String> allowed) {
      final value = json[key];
      return value is String && allowed.contains(value) ? value : fallback;
    }

    return AppSettings(
      useLocalProcessing: b('useLocalProcessing', d.useLocalProcessing),
      downloadMode: s('downloadMode', d.downloadMode, downloadModes),
      disableMetadata: b('disableMetadata', d.disableMetadata),
      autoDownloadFromShare: b('autoDownloadFromShare', d.autoDownloadFromShare),
      shareLinks: b('shareLinks', d.shareLinks),
      shareCopyToClipboard: b('shareCopyToClipboard', d.shareCopyToClipboard),
      showShareButton: b('showShareButton', d.showShareButton),
      audioBitrate: s('audioBitrate', d.audioBitrate, audioBitrates),
      audioFormat: s('audioFormat', d.audioFormat, audioFormats),
      videoQuality: s('videoQuality', d.videoQuality, videoQualities),
      showChangelogs: b('showChangelogs', d.showChangelogs),
      showBanner: b('showBanner', d.showBanner),
    );
  }
}
