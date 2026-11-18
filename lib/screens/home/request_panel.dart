import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/home_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../models/app_settings.dart';
import '../../models/server_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/cards.dart';
import '../../widgets/feedback.dart';
import '../../widgets/segmented_switch.dart';
import '../../widgets/svg_icon.dart';

/// Server picker, link field, download/share buttons and mode switch.
class RequestPanel extends StatelessWidget {
  const RequestPanel({
    super.key,
    required this.home,
    required this.urlController,
    required this.onAddCustomServer,
    required this.onDeleteServer,
  });

  final HomeController home;
  final TextEditingController urlController;
  final VoidCallback onAddCustomServer;
  final ValueChanged<ServerConfig> onDeleteServer;

  @override
  Widget build(BuildContext context) {
    final settings = home.settings.value;
    final hasServer = home.selected != null;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: urlController,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        final canSubmit = hasServer && hasText && !home.busy && !home.checkingServer;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ServerSelector(home: home, onAddCustom: onAddCustomServer, onDelete: onDeleteServer),
            const SizedBox(height: AppSpacing.gap),
            hasServer
                ? _UrlField(controller: urlController, enabled: !home.busy, hasText: value.text.isNotEmpty)
                : const _DisabledUrlField(),
            const SizedBox(height: AppSpacing.gap),
            Row(
              children: [
                Expanded(
                  child: _SubmitButton(
                    home: home,
                    settings: settings,
                    onPressed: canSubmit ? () => home.process(urlController.text) : null,
                    looksEnabled: hasServer && hasText && !home.busy,
                  ),
                ),
                if (settings.showShareButton) ...[
                  const SizedBox(width: AppSpacing.gap),
                  Tooltip(
                    message: LocaleKeys.ShareLinks.tr(),
                    child: SurfaceCard(
                      padding: EdgeInsets.zero,
                      onTap: home.toggleShareLinks,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: SvgIcon(settings.shareLinks ? AppIcons.share : AppIcons.download),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.gap),
            SegmentedSwitch<String>(
              values: AppSettings.downloadModes,
              selected: settings.downloadMode,
              labelOf: (mode) => switch (mode) {
                'audio' => LocaleKeys.AudioWithEmoji.tr(),
                'mute' => LocaleKeys.MuteWithEmoji.tr(),
                _ => LocaleKeys.AutoWithEmoji.tr(),
              },
              onSelected: hasServer && !home.busy ? home.setDownloadMode : null,
            ),
          ],
        );
      },
    );
  }
}

class _ServerSelector extends StatelessWidget {
  const _ServerSelector({required this.home, required this.onAddCustom, required this.onDelete});

  static const _addCustom = '\u0000add_custom';

  final HomeController home;
  final VoidCallback onAddCustom;
  final ValueChanged<ServerConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        prefixIcon: InputIcon(AppIcons.cloudDownload),
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: home.selected?.url ?? _addCustom,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 500,
          dropdownColor: AppColors.surface,
          borderRadius: AppRadii.cardBorder,
          icon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SvgIcon(AppIcons.selector, color: AppColors.textSecondary),
          ),
          items: [
            for (final server in home.servers)
              DropdownMenuItem(
                value: server.url,
                // Long-press a server in the open menu to delete it.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () {
                    Navigator.of(context).pop();
                    Future.microtask(() => onDelete(server));
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          server.displayLabel,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (server.hasApiKey) ...[
                        const SizedBox(width: 4),
                        Pill(LocaleKeys.KEY.tr(), color: AppColors.success),
                      ],
                    ],
                  ),
                ),
              ),
            DropdownMenuItem(
              value: _addCustom,
              child: Text(
                LocaleKeys.AddCustomServer.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: home.servers.isEmpty ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
          onChanged: home.busy
              ? null
              : (value) {
                  if (value == _addCustom) {
                    onAddCustom();
                  } else if (value != null) {
                    home.selectServer(value);
                  }
                },
        ),
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({required this.controller, required this.enabled, required this.hasText});

  final TextEditingController controller;
  final bool enabled;
  final bool hasText;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.url,
      autocorrect: false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: LocaleKeys.PasteTheLinkHere.tr(),
        prefixIcon: const InputIcon(AppIcons.link),
        suffixIcon: hasText
            ? IconButton(
                icon: const SvgIcon(AppIcons.backspace, color: AppColors.textSecondary),
                onPressed: enabled ? controller.clear : null,
              )
            : IconButton(
                icon: const SvgIcon(AppIcons.clipboardText, color: AppColors.textSecondary),
                tooltip: LocaleKeys.PasteFromClipboard.tr(),
                onPressed: enabled ? _paste : null,
              ),
      ),
    );
  }
}

class _DisabledUrlField extends StatelessWidget {
  const _DisabledUrlField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      style: const TextStyle(fontSize: 14, color: AppColors.textDisabled),
      decoration: InputDecoration(
        hintText: LocaleKeys.PleaseAddAServerFirst.tr(),
        prefixIcon: const InputIcon(AppIcons.link, color: Colors.white30, size: 20),
        filled: true,
        fillColor: Colors.black45,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.home,
    required this.settings,
    required this.onPressed,
    required this.looksEnabled,
  });

  final HomeController home;
  final AppSettings settings;
  final VoidCallback? onPressed;
  final bool looksEnabled;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (home.checkingServer || home.requesting) {
      child = const Skeleton(height: 16, width: 80);
    } else if (home.downloading) {
      child = Text(
        home.progressLabel ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: home.downloadSucceeded ? AppColors.success : AppColors.textPrimary,
        ),
      );
    } else {
      child = Text(
        home.showCopied
            ? LocaleKeys.Copied.tr()
            : settings.shareLinks
                ? LocaleKeys.Share.tr()
                : LocaleKeys.Download.tr(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 44),
        fixedSize: const Size.fromHeight(44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: looksEnabled ? AppColors.text : AppColors.textDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(
            color: looksEnabled ? AppColors.border : AppColors.borderSubtle,
            width: 1.5,
          ),
        ),
      ),
      child: child,
    );
  }
}
