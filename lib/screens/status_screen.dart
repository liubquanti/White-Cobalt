import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/app_urls.dart';
import '../generated/codegen_loader_keys.g.dart';
import '../models/misc.dart';
import '../services/remote_data.dart';
import '../theme/app_colors.dart';
import '../utils/navigation.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  late Future<List<MonitorStatus>> _future = RemoteData.serviceStatus();

  void _retry() => setState(() => _future = RemoteData.serviceStatus());

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.ServiceStatus.tr(),
      body: FutureBuilder<List<MonitorStatus>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) {
            return ErrorRetryView(
              message: LocaleKeys
                  .AnErrorOccurredWhileLoadingServiceStatusesPleaseTryAgainOrCheckTheInformationInYourBrowser
                  .tr(),
              actions: [
                ErrorAction(LocaleKeys.Retry.tr(), _retry),
                // canLaunchUrl() always returned false on Android 11+ without
                // a <queries> entry, so this button used to do nothing.
                ErrorAction(LocaleKeys.InBrowser.tr(), () => openExternalUrl(AppUrls.statusPage)),
              ],
            );
          }
          return PageScrollView(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: separated([for (final m in snapshot.data!) _MonitorCard(monitor: m)]),
          );
        },
      ),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  const _MonitorCard({required this.monitor});

  final MonitorStatus monitor;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (monitor.statusClass) {
      'success' => (AppColors.success, LocaleKeys.Online.tr()),
      'danger' => (AppColors.error, LocaleKeys.Offline.tr()),
      'warning' => (AppColors.caution, LocaleKeys.Warning.tr()),
      _ => (Colors.grey, LocaleKeys.Unknown.tr()),
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monitor.name ?? LocaleKeys.Unknown.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Pill(label, color: color, textColor: Colors.white),
            ],
          ),
          if (monitor.dailyColors.isNotEmpty) ...[
            Text(LocaleKeys.Last90Days.tr(), style: AppTextStyles.body),
            const SizedBox(height: 6),
            SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final day in monitor.dailyColors)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: _dayColor(day),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _dayColor(String name) => switch (name) {
        'green' => AppColors.success,
        'red' => AppColors.error,
        'yellow' => AppColors.caution,
        'blue' => Colors.blue,
        _ => Colors.grey,
      };
}
