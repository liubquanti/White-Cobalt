import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../models/cobalt_response.dart';
import '../../services/cobalt_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/cards.dart';
import '../../widgets/feedback.dart';
import '../../widgets/svg_icon.dart';

/// Items of a multi-media ("picker") response, each downloadable separately.
class PickerList extends StatelessWidget {
  const PickerList({super.key, required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final items = home.pickerItems;
    final serverUrl = home.selected?.url ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: separated([
        for (final (index, item) in items.indexed)
          SurfaceCard(
            borderColor: AppColors.borderSubtle,
            child: Row(
              children: [
                _Thumbnail(item: item, serverUrl: serverUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${item.type} #${index + 1}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const SvgIcon(AppIcons.download),
                  onPressed: home.busy ? null : () => home.downloadPickerItem(item),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.serverUrl});

  final PickerItem item;
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumb;
    if (thumb == null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(5)),
        child: Icon(
          switch (item.type) {
            'photo' => Icons.image,
            'gif' => Icons.gif,
            _ => Icons.video_library,
          },
          size: 32,
          color: AppColors.textSecondary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        CobaltApi.resolveMediaUrl(thumb, serverUrl),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.square(
          dimension: 50,
          child: Center(child: SvgIcon(AppIcons.photoOff, color: AppColors.textDisabled)),
        ),
      ),
    );
  }
}

/// The single status card under the controls. Shows, by priority: API error
/// details, server check in progress, an error status, server info, "no
/// server", or the latest informational status.
class HomeStatusCard extends StatelessWidget {
  const HomeStatusCard({super.key, required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final error = home.errorResponse;
    final status = home.status;
    final info = home.serverInfo;

    if (error != null) {
      return InfoCard(
        icon: AppIcons.exclamationCircle,
        iconColor: AppColors.error,
        title: LocaleKeys.ServerError.tr(),
        lines: [
          Text(error.errorCode ?? '?', style: AppTextStyles.small),
          if (error.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(error.errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF))),
            ),
        ],
      );
    }
    if (home.checkingServer) return const _StatusSkeleton();
    if (status?.kind == StatusKind.error) {
      return InfoCard(
        icon: AppIcons.exclamationCircle,
        iconColor: AppColors.error,
        title: LocaleKeys.Error.tr(),
        lines: [Text(status!.text, style: AppTextStyles.small)],
      );
    }
    if (info != null && home.selected != null) {
      return InfoCard(
        icon: AppIcons.circleCheck,
        iconColor: AppColors.success,
        title: '${LocaleKeys.Cobalt.tr()} v${info.version}',
        lines: [
          Text(LocaleKeys.SupportedServices.tr(args: ['${info.servicesCount}']), style: AppTextStyles.small),
        ],
      );
    }
    if (home.selected == null) {
      return InfoCard(
        icon: AppIcons.server,
        iconColor: AppColors.warning,
        title: LocaleKeys.NoServerSelected.tr(),
        lines: [Text(LocaleKeys.PleaseSelectAServerFirst.tr(), style: AppTextStyles.small)],
      );
    }
    if (status != null) {
      return InfoCard(
        icon: AppIcons.infoCircle,
        iconColor: AppColors.warning,
        title: LocaleKeys.Status.tr(),
        lines: [Text(status.text, style: AppTextStyles.small)],
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(height: 16, width: 16),
              SizedBox(width: 10),
              Skeleton(height: 16, width: 150),
            ],
          ),
          SizedBox(height: 10),
          Skeleton(height: 15, width: 150),
        ],
      ),
    );
  }
}
