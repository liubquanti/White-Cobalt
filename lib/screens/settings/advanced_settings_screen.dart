import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../controllers/settings_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../models/app_settings.dart';
import '../../theme/app_icons.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/settings_tiles.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.AdvancedSettings.tr(),
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
                    icon: AppIcons.fileDownload,
                    title: LocaleKeys.NoMetadata.tr(),
                    subtitle: LocaleKeys.RemoveInfoFromFiles.tr(),
                    value: s.disableMetadata,
                    onChanged: (v) => settings.update((s) => s.copyWith(disableMetadata: v)),
                  ),
                  SwitchTile(
                    icon: AppIcons.clipboardPlus,
                    title: LocaleKeys.CopyShareLinks.tr(),
                    subtitle: LocaleKeys.CopyToClipboardInsteadOfOpeningShareMenu.tr(),
                    value: s.shareCopyToClipboard,
                    onChanged: (v) => settings.update((s) => s.copyWith(shareCopyToClipboard: v)),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.Video.tr(),
                children: [
                  DropdownTile(
                    icon: AppIcons.badgeHd,
                    title: LocaleKeys.VideoQuality.tr(),
                    subtitle: LocaleKeys.MaximumQualityForVideoDownloads.tr(),
                    value: s.videoQuality,
                    options: AppSettings.videoQualities,
                    onChanged: (v) => settings.update((s) => s.copyWith(videoQuality: v)),
                  ),
                ],
              ),
              Section(
                title: LocaleKeys.Audio.tr(),
                children: [
                  DropdownTile(
                    icon: AppIcons.adjustments,
                    title: LocaleKeys.AudioBitrate.tr(),
                    subtitle: LocaleKeys.MaximumBitrateForAudioDownloads.tr(),
                    value: s.audioBitrate,
                    options: AppSettings.audioBitrates,
                    onChanged: (v) => settings.update((s) => s.copyWith(audioBitrate: v)),
                  ),
                  DropdownTile(
                    icon: AppIcons.fileMusic,
                    title: LocaleKeys.AudioFormat.tr(),
                    subtitle: LocaleKeys.FileFormatForAudioDownloads.tr(),
                    value: s.audioFormat,
                    options: AppSettings.audioFormats,
                    onChanged: (v) => settings.update((s) => s.copyWith(audioFormat: v)),
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
