/// Every external endpoint and link the app talks to, in one place.
abstract final class AppUrls {
  static const _repoRaw = 'https://raw.githubusercontent.com/liubquanti/White-Cobalt/refs/heads/main';

  // Remote data
  static const officialServers = '$_repoRaw/files/servers.json';
  static const homeBanner = '$_repoRaw/files/banner.json';
  static const remotePubspec = '$_repoRaw/pubspec.yaml';
  static const kwiatInstances = 'https://instances.cobalt.best/instances.json';
  static const hyperInstances = 'https://cobalt.directory/api/tests';
  static const cobaltChangelogs = 'https://api.github.com/repos/imputnet/cobalt/contents/web/changelogs';
  static const cobaltUpdateBanners = 'https://github.com/imputnet/cobalt/raw/main/web/static/update-banners/';
  static const cobaltUpdates = 'https://cobalt.tools/updates#';
  static const statusApi = 'https://stats.uptimerobot.com/api/getMonitorList/NowpAIVNnk';
  static const statusPage = 'https://stats.uptimerobot.com/NowpAIVNnk';

  // About page
  static const playStore = 'https://play.google.com/store/apps/details?id=liubquanti.white.cobalt';
  static const repository = 'https://github.com/liubquanti/White-Cobalt';
}
