import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/changelog_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../models/server_config.dart';
import '../../services/native_bridge.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/svg_icon.dart';
import '../instances_screen.dart';
import '../settings/settings_screen.dart';
import 'home_feed.dart';
import 'request_panel.dart';
import 'result_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _home = HomeController(settings: widget.settings);
  final _changelogs = ChangelogController();
  final _urlController = TextEditingController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _home.init();
    widget.settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
    // A share intent can arrive at launch or while the app is backgrounded.
    _lifecycle = AppLifecycleListener(onResume: _consumeSharedUrl);
    _consumeSharedUrl();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.settings.removeListener(_onSettingsChanged);
    _home.dispose();
    _changelogs.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    // Only hit the GitHub API when the feed is actually shown.
    if (widget.settings.value.showChangelogs) _changelogs.ensureLoaded();
  }

  Future<void> _consumeSharedUrl() async {
    final url = await NativeBridge.takeSharedUrl();
    if (url == null || !mounted) return;
    _urlController.text = url;
    await _home.handleSharedUrl(url);
  }

  Future<void> _addCustomServer() async {
    final input = await showAddServerDialog(context, title: LocaleKeys.AddCustomServer.tr());
    if (input != null) await _home.addCustomServer(input.url, input.apiKey);
  }

  Future<void> _deleteServer(ServerConfig server) async {
    final confirmed = await showConfirmDialog(
      context,
      title: LocaleKeys.DeleteServer.tr(),
      message: LocaleKeys.AreYouSureYouWantToDeleteThisServer.tr(args: [server.url]),
      confirmLabel: LocaleKeys.Delete.tr(),
      destructive: true,
    );
    if (confirmed) await _home.deleteServer(server.url);
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.WhiteCobalt.tr()),
        leading: IconButton(
          icon: const SvgIcon(AppIcons.server),
          tooltip: LocaleKeys.Servers.tr(),
          onPressed: () => _open(InstancesScreen(onServerAdded: _home.addServer)),
        ),
        actions: [
          IconButton(
            icon: const SvgIcon(AppIcons.settings),
            tooltip: LocaleKeys.Settings.tr(),
            onPressed: () => _open(SettingsScreen(settings: widget.settings)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_home, widget.settings]),
        builder: (context, _) {
          final hasPicker = _home.pickerItems.isNotEmpty;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              MediaQuery.paddingOf(context).bottom + AppSpacing.page,
            ),
            children: [
              SvgPicture.asset(
                'assets/heart/Heart Lisa.svg',
                height: 120,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(height: AppSpacing.page),
              RequestPanel(
                home: _home,
                urlController: _urlController,
                onAddCustomServer: _addCustomServer,
                onDeleteServer: _deleteServer,
              ),
              const SizedBox(height: AppSpacing.gap),
              const Divider(),
              const SizedBox(height: AppSpacing.gap),
              if (hasPicker) ...[
                PickerList(home: _home),
                const SizedBox(height: AppSpacing.gap),
                const Divider(),
                const SizedBox(height: AppSpacing.gap),
              ],
              HomeStatusCard(home: _home),
              const SizedBox(height: AppSpacing.gap),
              HomeFeed(settings: widget.settings, changelogs: _changelogs),
            ],
          );
        },
      ),
    );
  }
}
