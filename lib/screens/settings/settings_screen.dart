import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../controllers/settings_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../theme/app_icons.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/settings_tiles.dart';
import '../status_screen.dart';
import 'about_screen.dart';
import 'advanced_settings_screen.dart';
import 'language_screen.dart';
import 'storage_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.Settings.tr(),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final s = settings.value;
          return PageScrollView(
            children: [
              Section(
                first: true,
                title: LocaleKeys.Downloads.tr(),
                children: [
                  SwitchTile(
                    icon: AppIcons.cpu,
                    title: LocaleKeys.LocalProcessing.tr(),
                    subtitle: LocaleKeys.ProcessMediaOnTheClientSide.tr(),
                    value: s.useLocalProcessing,
                    onChanged: (v) => settings.update((s) => s.copyWith(useLocalProcessing: v)),
                  ),
                  SwitchTile(
                    icon: AppIcons.share,
                    title: LocaleKeys.ShareLinks.tr(),
                    subtitle: LocaleKeys.ShareLinksInsteadOfDownloadingFiles.tr(),
                    value: s.shareLinks,
                    onChanged: (v) => settings.update((s) => s.copyWith(shareLinks: v)),
                  ),
                  SwitchTile(
                    icon: AppIcons.link,
                    title: LocaleKeys.AutoDownloadFromShare.tr(),
                    subtitle: LocaleKeys.AutomaticallyStartDownloadingWhenALinkIsSharedToTheApp.tr(),
                    value: s.autoDownloadFromShare,
                    onChanged: (v) => settings.update((s) => s.copyWith(autoDownloadFromShare: v)),
                  ),
                  NavTile(
                    icon: AppIcons.settingsCog,
                    title: LocaleKeys.AdvancedSettings.tr(),
                    onTap: () => pushPage(context, AdvancedSettingsScreen(settings: settings)),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.Interface.tr(),
                children: [
                  SwitchTile(
                    icon: AppIcons.ad,
                    title: LocaleKeys.ShowBanner.tr(),
                    subtitle: LocaleKeys.DisplayBannerOnHomeScreen.tr(),
                    value: s.showBanner,
                    onChanged: (v) => settings.update((s) => s.copyWith(showBanner: v)),
                  ),
                  SwitchTile(
                    icon: AppIcons.gitCherryPick,
                    title: LocaleKeys.ShowChangelogs.tr(),
                    subtitle: LocaleKeys.DisplayAPIChangelogsOnHomeScreen.tr(),
                    value: s.showChangelogs,
                    onChanged: (v) => settings.update((s) => s.copyWith(showChangelogs: v)),
                  ),
                  SwitchTile(
                    icon: AppIcons.share,
                    title: LocaleKeys.ShowShareButton.tr(),
                    subtitle: LocaleKeys.DisplayTheShareDownloadToggleButtonOnHomeScreen.tr(),
                    value: s.showShareButton,
                    onChanged: (v) => settings.update((s) => s.copyWith(showShareButton: v)),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.Storage.tr(),
                children: [
                  NavTile(
                    icon: AppIcons.database,
                    title: LocaleKeys.StorageUsage.tr(),
                    onTap: () => pushPage(context, const StorageScreen()),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.System.tr(),
                children: [
                  NavTile(
                    icon: AppIcons.chartBar,
                    title: LocaleKeys.ServiceStatus.tr(),
                    onTap: () => pushPage(context, const StatusScreen()),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.Language.tr(),
                children: [
                  NavTile(
                    icon: AppIcons.language,
                    title: LocaleKeys.ChangeLanguage.tr(),
                    onTap: () => pushPage(context, const LanguageScreen()),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.About.tr(),
                children: [
                  NavTile(
                    icon: AppIcons.infoCircle,
                    title: LocaleKeys.AppInformation.tr(),
                    onTap: () => pushPage(context, const AboutScreen()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
