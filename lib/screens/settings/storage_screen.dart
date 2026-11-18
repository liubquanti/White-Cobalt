import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../generated/codegen_loader_keys.g.dart';
import '../../models/misc.dart';
import '../../services/native_bridge.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../utils/formatters.dart';
import '../../utils/logger.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/feedback.dart';
import '../../widgets/svg_icon.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _loading = true;
  List<ServiceUsage> _usage = const [];
  DeviceStorage? _device;
  int _touchedIndex = -1;

  int get _total => _usage.fold(0, (sum, u) => sum + u.bytes);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<ServiceUsage> usage = const [];
    try {
      usage = await StorageService.scan();
    } catch (e) {
      logDebug('Storage scan failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _usage = usage;
      _loading = false;
    });
    final device = await NativeBridge.storageStats();
    if (mounted) setState(() => _device = device);
  }

  Future<void> _delete(String service) async {
    final confirmed = await showConfirmDialog(
      context,
      title: LocaleKeys.DeleteFiles.tr(args: [service]),
      message: LocaleKeys.AreYouSureYouWantToDeleteAllDownloadedFilesFrom.tr(args: [service]),
      confirmLabel: LocaleKeys.Delete.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await StorageService.deleteService(service);
      messenger.showSnackBar(SnackBar(
        content: Text(deleted
            ? LocaleKeys.FilesDeletedSuccessfully.tr(args: [service])
            : LocaleKeys.NoDirectoriesFoundForThisService.tr()),
        backgroundColor: deleted ? AppColors.success : AppColors.warning,
      ));
      if (deleted) await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(LocaleKeys.CouldNotDeleteDirectory.tr(args: ['$e'])),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.StorageUsage.tr(),
      body: _loading
          ? const LoadingView()
          : _total == 0
              ? const _EmptyState()
              : PageScrollView(
                  top: AppSpacing.page,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      LocaleKeys.Total.tr(args: [
                        '${formatBytes(_total)} / ${_device == null ? '…' : formatBytes(_device!.total)}',
                      ]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 250, child: _buildChart()),
                    const _Legend(),
                    const SizedBox(height: AppSpacing.gap),
                    ...separated([
                      for (final (i, usage) in _usage.indexed)
                        _ServiceRow(
                          usage: usage,
                          color: AppColors.chart[i % AppColors.chart.length],
                          onDelete: () => _delete(usage.service),
                        ),
                    ]),
                  ],
                ),
    );
  }

  Widget _buildChart() {
    final total = _total;
    final device = _device;
    final share = device == null || device.total <= 0 ? 0.0 : total / device.total * 100;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                final index = event.isInterestedForInteractions
                    ? response?.touchedSection?.touchedSectionIndex ?? -1
                    : -1;
                if (index != _touchedIndex) setState(() => _touchedIndex = index);
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: [
              for (final (i, usage) in _usage.indexed)
                PieChartSectionData(
                  color: AppColors.chart[i % AppColors.chart.length],
                  value: usage.bytes.toDouble(),
                  title: '${(usage.bytes / total * 100).toStringAsFixed(1)}%',
                  radius: i == _touchedIndex ? 60 : 50,
                  titleStyle: TextStyle(
                    fontSize: i == _touchedIndex ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        if (device == null)
          const AppSpinner(size: 30)
        else if (device.total > 0)
          SizedBox.square(
            dimension: 60,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                centerSpaceRadius: 40,
                sections: [
                  _ring(Colors.white, total),
                  _ring(AppColors.storageOther, device.used - total),
                  _ring(AppColors.selected, device.free),
                ],
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SvgIcon(AppIcons.database, size: 24),
            Text(
              '${share.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  static PieChartSectionData _ring(Color color, int value) => PieChartSectionData(
        color: color,
        // Negative values (e.g. files on another volume) would break the chart.
        value: value < 0 ? 0 : value.toDouble(),
        radius: 10,
        showTitle: false,
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SvgIcon(AppIcons.filesOff, size: 64, color: Colors.white30),
            Text(LocaleKeys.NoDownloadsYet.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.WhenYouDownloadFilesUsingWhiteCobaltHereWillBeStorageUsageStats.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xB3FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.tileTitle),
          ],
        );

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          item(Colors.white, LocaleKeys.Cobalt.tr()),
          item(AppColors.storageOther, LocaleKeys.Other.tr()),
          item(AppColors.selected, LocaleKeys.Free.tr()),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 15, height: 15, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.usage, required this.color, required this.onDelete});

  final ServiceUsage usage;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Dot(color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usage.service, style: AppTextStyles.tileTitle),
                const SizedBox(height: 2),
                Text(formatBytes(usage.bytes), style: AppTextStyles.caption),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onDelete,
            icon: const SvgIcon(AppIcons.trash, size: 18),
            label: Text(
              LocaleKeys.Delete.tr(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
