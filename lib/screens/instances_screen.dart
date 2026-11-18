import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/codegen_loader_keys.g.dart';
import '../models/instances.dart';
import '../models/server_config.dart';
import '../services/remote_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/navigation.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/cards.dart';
import '../widgets/dialogs.dart';
import '../widgets/feedback.dart';
import '../widgets/segmented_switch.dart';
import 'status_screen.dart';

/// Browser of official and community-listed cobalt instances.
class InstancesScreen extends StatefulWidget {
  const InstancesScreen({super.key, required this.onServerAdded});

  final ValueChanged<ServerConfig> onServerAdded;

  @override
  State<InstancesScreen> createState() => _InstancesScreenState();
}

class _InstancesScreenState extends State<InstancesScreen> {
  late Future<InstanceLists> _future = RemoteData.instanceLists();

  void _retry() => setState(() => _future = RemoteData.instanceLists());

  Future<void> _add({
    required String apiUrl,
    required Widget header,
    String? name,
    bool isOfficial = false,
  }) async {
    final input = await showAddServerDialog(
      context,
      title: LocaleKeys.AddServer.tr(),
      fixedUrl: apiUrl,
      header: header,
    );
    if (input == null || !mounted) return;
    widget.onServerAdded(ServerConfig(url: apiUrl, apiKey: input.apiKey, name: name, isOfficial: isOfficial));
    Navigator.of(context).pop();
  }

  void _addOfficial(OfficialServer server) => _add(
        apiUrl: server.apiUrl,
        name: server.name,
        isOfficial: true,
        header: Text(server.api, style: AppTextStyles.body),
      );

  void _addInstance(CobaltInstance instance) => _add(
        apiUrl: instance.apiUrl,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instance.api, style: AppTextStyles.body),
            Text(
              LocaleKeys.Score.tr(args: ['${instance.score}']),
              style: TextStyle(fontSize: 14, color: _scoreColor(instance.score)),
            ),
          ],
        ),
      );

  void _copyApiUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocaleKeys.APIURLCopiedToClipboard.tr()), duration: const Duration(seconds: 2)),
    );
  }

  Widget _errorView() => ErrorRetryView(
        message: LocaleKeys.AnErrorOccurredWhileLoadingTheListOfInstancesPleaseTryAgainOrCheckTheServiceStatus.tr(),
        actions: [
          ErrorAction(LocaleKeys.Retry.tr(), _retry),
          ErrorAction(LocaleKeys.ServiceStatus.tr(), () => pushPage(context, const StatusScreen())),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.ServersBrowser.tr(),
      body: FutureBuilder<InstanceLists>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final lists = snapshot.data;
          if (lists == null || lists.isEmpty) return _errorView();
          return _buildLists(lists);
        },
      ),
    );
  }

  Widget _buildLists(InstanceLists lists) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget tab(List<CobaltInstance> instances) {
      if (instances.isEmpty) {
        return ListView(padding: const EdgeInsets.only(top: 20), children: [_errorView()]);
      }
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, bottom + AppSpacing.page),
        itemCount: instances.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gap),
        itemBuilder: (_, i) => _instanceCard(instances[i]),
      );
    }

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverList.list(
              children: [
                if (lists.official.isNotEmpty)
                  Section(
                    first: true,
                    title: LocaleKeys.OfficialInstances.tr(),
                    children: [for (final s in lists.official) _officialCard(s)],
                  ),
                if (lists.kwiat.isNotEmpty || lists.hyper.isNotEmpty) ...[
                  if (lists.official.isNotEmpty) const SizedBox(height: AppSpacing.section),
                  Text(LocaleKeys.PublicInstances.tr(), style: AppTextStyles.sectionTitle),
                ],
              ],
            ),
          ),
          SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate(DefaultTabController.of(context))),
        ],
        body: TabBarView(children: [tab(lists.hyper), tab(lists.kwiat)]),
      ),
    );
  }

  Widget _officialCard(OfficialServer server) {
    return _ServerCard(
      header: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            server.logo,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.square(dimension: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(server.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitle)),
        Pill(LocaleKeys.Official.tr()),
      ],
      details: [Text(server.reason, style: AppTextStyles.caption)],
      dividerAfterHeader: false,
      auth: server.auth,
      frontendUrl: server.frontendUrl,
      onAdd: () => _addOfficial(server),
      onCopy: () => _copyApiUrl(server.apiUrl),
    );
  }

  Widget _instanceCard(CobaltInstance instance) {
    return _ServerCard(
      header: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: instance.isOnline ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(instance.api, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitle)),
        Pill('${instance.score}', color: _scoreColor(instance.score), textColor: Colors.white, width: 40),
      ],
      details: [
        Text('${LocaleKeys.Protocol.tr()}: ${instance.protocol}', style: AppTextStyles.caption),
        Text('${LocaleKeys.Services.tr()}: ${instance.servicesCount}', style: AppTextStyles.caption),
        Text('${LocaleKeys.Version.tr()}: ${instance.version ?? '?'}', style: AppTextStyles.caption),
      ],
      auth: instance.auth,
      frontendUrl: instance.frontendUrl,
      onAdd: () => _addInstance(instance),
      onCopy: () => _copyApiUrl(instance.apiUrl),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.caution;
    if (score >= 20) return AppColors.warning;
    return AppColors.error;
  }
}

/// Card layout shared by official servers and public instances.
class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.header,
    required this.details,
    required this.auth,
    required this.frontendUrl,
    required this.onAdd,
    required this.onCopy,
    this.dividerAfterHeader = true,
  });

  final List<Widget> header;
  final bool dividerAfterHeader;
  final List<Widget> details;
  final bool? auth;
  final String? frontendUrl;
  final VoidCallback onAdd;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final (authLabel, authColor) = switch (auth) {
      true => (LocaleKeys.AuthRequired.tr(), AppColors.error),
      false => (LocaleKeys.OpenAccess.tr(), AppColors.success),
      null => (LocaleKeys.AuthInfoUnavailable.tr(), AppColors.textSecondary),
    };
    const divider = Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.gap), child: Divider());

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: header),
          if (dividerAfterHeader) divider else const SizedBox(height: 5),
          ...details,
          divider,
          Text(authLabel, style: TextStyle(fontSize: 12, color: authColor, fontWeight: FontWeight.w600)),
          divider,
          Wrap(
            spacing: AppSpacing.gap,
            runSpacing: AppSpacing.gap,
            children: [
              BorderedIconButton(
                icon: AppIcons.serverSpark,
                label: LocaleKeys.AddServer.tr(),
                onTap: () async {
                  await Future<void>.delayed(rippleDelay);
                  onAdd();
                },
              ),
              if (frontendUrl != null)
                BorderedIconButton(icon: AppIcons.world, onTap: () => openExternalUrl(frontendUrl)),
              BorderedIconButton(icon: AppIcons.api, onTap: onCopy),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.controller);

  final TabController controller;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, 10),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SegmentedSwitch<int>(
            values: const [0, 1],
            selected: controller.index,
            labelOf: (i) => i == 0 ? 'Hyper' : 'Kwiat',
            onSelected: (i) => controller.animateTo(i),
            height: 36,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => oldDelegate.controller != controller;
}
