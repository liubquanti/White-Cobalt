import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:white_cobalt/generated/codegen_loader_keys.g.dart';

import '../models/instance.dart';
import '../models/oinstance.dart';
import '../services/instances.dart';
import '../services/oinstances.dart';
import '../config/server.dart';
import 'status.dart';

class InstancesScreen extends StatefulWidget {
  final Function(ServerConfig) onServerAdded;

  const InstancesScreen({
    Key? key,
    required this.onServerAdded,
  }) : super(key: key);

  @override
  State<InstancesScreen> createState() => _InstancesScreenState();
}

class _InstancesScreenState extends State<InstancesScreen> {
  bool _isLoading = true;
  List<CobaltInstance> _kwiatInstances = [];
  List<CobaltInstance> _hyperInstances = [];
  List<OfficialServer> _officialServers = [];
  String _error = '';
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final officialFuture = OfficialServersService.fetchOfficialServers();
      final instancesFuture = InstancesService.fetchInstances();

      final officialServers = await officialFuture;
      final instancesResponse = await instancesFuture;

      final kwiatInstances = List<CobaltInstance>.from(instancesResponse.kwiat)
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return b.score.compareTo(a.score);
        });

      final hyperInstances = List<CobaltInstance>.from(instancesResponse.hyper)
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return b.score.compareTo(a.score);
        });

      setState(() {
        _officialServers = officialServers;
        _kwiatInstances = kwiatInstances;
        _hyperInstances = hyperInstances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = LocaleKeys.FailedToLoadData.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _addOfficialServerWithConfirmation(OfficialServer server) async {
    _apiKeyController.clear();

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            LocaleKeys.AddServer.tr(),
            style: const TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: const BorderSide(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              width: 2.0,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                server.api,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.APIKeyOptional.tr(),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: LocaleKeys.APIKey.tr(),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.5, color: Color(0xFF383838)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 2.0, color: Colors.white),
                  ),
                  prefixIcon: SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: SvgPicture.string(
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-key"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0z" /><path d="M15 9h.01" /></svg>',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                ),
                style: const TextStyle(fontSize: 14),
                cursorColor: const Color(0xFFE1E1E1),
              ),
              const SizedBox(height: 5),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                backgroundColor: const Color(0xFF191919),
                foregroundColor: const Color(0xFFe1e1e1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(
                    color: Color.fromRGBO(255, 255, 255, 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                final apiKey = _apiKeyController.text.trim();
                final serverConfig = ServerConfig(
                  server.apiUrl,
                  apiKey.isNotEmpty ? apiKey : null,
                );

                widget.onServerAdded(serverConfig);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                backgroundColor: const Color(0xFF191919),
                foregroundColor: const Color(0xFFe1e1e1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(
                    color: Color.fromRGBO(255, 255, 255, 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(LocaleKeys.Add.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addInstanceWithConfirmation(CobaltInstance instance) async {
    _apiKeyController.clear();

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            LocaleKeys.AddServer.tr(),
            style: const TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: const BorderSide(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              width: 2.0,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.api,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                LocaleKeys.Score.tr(args: [instance.score.toString()]),
                style: TextStyle(
                  fontSize: 14,
                  color: _getScoreColor(instance.score),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.APIKeyOptional.tr(),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: LocaleKeys.APIKey.tr(),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 2.0, color: Colors.white),
                  ),
                  prefixIcon: SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: SvgPicture.string(
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-key"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0z" /><path d="M15 9h.01" /></svg>',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                ),
                style: const TextStyle(fontSize: 14),
                cursorColor: const Color(0xFFE1E1E1),
              ),
              const SizedBox(height: 5),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                backgroundColor: const Color(0xFF191919),
                foregroundColor: const Color(0xFFe1e1e1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(
                    color: Color.fromRGBO(255, 255, 255, 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                final apiKey = _apiKeyController.text.trim();
                final serverConfig = ServerConfig(
                  instance.apiUrl,
                  apiKey.isNotEmpty ? apiKey : null,
                );

                widget.onServerAdded(serverConfig);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                backgroundColor: const Color(0xFF191919),
                foregroundColor: const Color(0xFFe1e1e1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(
                    color: Color.fromRGBO(255, 255, 255, 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(LocaleKeys.Add.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(LocaleKeys.ServersBrowser.tr()),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: SvgPicture.string(
            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-chevron-left"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 6l-6 6l6 6" /></svg>',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          year2023: false,
          color: Colors.white,
          backgroundColor: Colors.grey,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                LocaleKeys
                        .AnErrorOccurredWhileLoadingTheListOfInstancesPleaseTryAgainOrCheckTheServiceStatus
                    .tr(),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    backgroundColor: const Color(0xFF191919),
                    foregroundColor: const Color(0xFFe1e1e1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: const BorderSide(
                        color: Color.fromRGBO(255, 255, 255, 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(LocaleKeys.Retry.tr()),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await Future.delayed(const Duration(milliseconds: 250));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServiceStatusScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    backgroundColor: const Color(0xFF191919),
                    foregroundColor: const Color(0xFFe1e1e1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: const BorderSide(
                        color: Color.fromRGBO(255, 255, 255, 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(LocaleKeys.ServiceStatus.tr()),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          final List<Widget> headerChildren = [];
          final bool hasOfficial = _officialServers.isNotEmpty;
          final bool hasPublic = _kwiatInstances.isNotEmpty || _hyperInstances.isNotEmpty;

          if (hasOfficial) {
            headerChildren
              ..add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    LocaleKeys.OfficialInstances.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              ..addAll(
                _officialServers.map(_buildOfficialServerCard),
              )
              ..add(const SizedBox(height: 4));
          }

          if (hasPublic) {
            headerChildren.add(
              Text(
                LocaleKeys.PublicInstances.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          final tabController = DefaultTabController.of(context);

          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headerChildren,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _InstancesTabBarDelegate(
                tabController,
              ),
            ),
          ];
        },
        body: Container(
          color: Colors.black,
          child: TabBarView(
            children: [
              _buildInstancesTabContent(
                context,
                _kwiatInstances,
              ),
              _buildInstancesTabContent(
                context,
                _hyperInstances,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialServerCard(OfficialServer server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF191919),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(
          color: Color(0x13FFFFFF),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(server.logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    server.api,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LocaleKeys.Official.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.reason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Color(0xFF383838),
              thickness: 1.0,
              height: 1,
            ),
            const SizedBox(height: 10),
            _buildAuthStatusText(server.auth),
            const SizedBox(height: 10),
            const Divider(
              color: Color(0xFF383838),
              thickness: 1.0,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 250));
                      await _addOfficialServerWithConfirmation(server);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.string(
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-spark"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M19 22.5a4.75 4.75 0 0 1 3.5 -3.5a4.75 4.75 0 0 1 -3.5 -3.5a4.75 4.75 0 0 1 -3.5 3.5a4.75 4.75 0 0 1 3.5 3.5" /><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M12 20h-6a3 3 0 0 1 -3 -3v-2a3 3 0 0 1 3 -3h10.5" /><path d="M7 8v.01" /><path d="M7 16v.01" /></svg>',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LocaleKeys.AddServer.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (server.frontend != "None")
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        launchUrl(Uri.parse('${server.protocol}://${server.frontend}'));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: SvgPicture.string(
                          '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-world"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M3.6 9h16.8" /><path d="M3.6 15h16.8" /><path d="M11.5 3a17 17 0 0 0 0 18" /><path d="M12.5 3a17 17 0 0 1 0 18" /></svg>',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                if (server.frontend != "None") const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: server.apiUrl),
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(LocaleKeys.APIURLCopiedToClipboard.tr()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: SvgPicture.string(
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-api"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 13h5" /><path d="M12 16v-8h3a2 2 0 0 1 2 2v1a2 2 0 0 1 -2 2h-3" /><path d="M20 8v8" /><path d="M9 16v-5.5a2.5 2.5 0 0 0 -5 0v5.5" /></svg>',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstancesTabContent(
    BuildContext context,
    List<CobaltInstance> instances,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (instances.isEmpty) {
      return ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: bottomPadding + 16,
        ),
        children: [
          Center(
            child: Text(
              LocaleKeys.NoServersFound.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding,
      ),
      children: [
        ...instances.map(_buildInstanceCard),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildInstanceCard(CobaltInstance instance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF191919),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(
          color: Color(0x13FFFFFF),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: instance.isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instance.api,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getScoreColor(instance.score),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      '${instance.score}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Color(0xFF383838),
              thickness: 1.0,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocaleKeys.Protocol.tr()}: ${instance.protocol}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${LocaleKeys.Services.tr()}: ${instance.servicesCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${LocaleKeys.Version.tr()}: ${instance.version}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Color(0xFF383838),
              thickness: 1.0,
              height: 1,
            ),
            const SizedBox(height: 10),
            _buildAuthStatusText(instance.auth),
            const SizedBox(height: 10),
            const Divider(
              color: Color(0xFF383838),
              thickness: 1.0,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 250));
                      await _addInstanceWithConfirmation(instance);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.string(
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-spark"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M19 22.5a4.75 4.75 0 0 1 3.5 -3.5a4.75 4.75 0 0 1 -3.5 -3.5a4.75 4.75 0 0 1 -3.5 3.5a4.75 4.75 0 0 1 3.5 3.5" /><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M12 20h-6a3 3 0 0 1 -3 -3v-2a3 3 0 0 1 3 -3h10.5" /><path d="M7 8v.01" /><path d="M7 16v.01" /></svg>',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LocaleKeys.AddServer.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (instance.frontend != null && instance.frontend != "None" && instance.frontend!.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        launchUrl(Uri.parse('${instance.protocol}://${instance.frontend}'));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: SvgPicture.string(
                          '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-world"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M3.6 9h16.8" /><path d="M3.6 15h16.8" /><path d="M11.5 3a17 17 0 0 0 0 18" /><path d="M12.5 3a17 17 0 0 1 0 18" /></svg>',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                if (instance.frontend != null && instance.frontend != "None" && instance.frontend!.isNotEmpty)
                  const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: instance.apiUrl),
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(LocaleKeys.APIURLCopiedToClipboard.tr()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: SvgPicture.string(
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-api"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 13h5" /><path d="M12 16v-8h3a2 2 0 0 1 2 2v1a2 2 0 0 1 -2 2h-3" /><path d="M20 8v8" /><path d="M9 16v-5.5a2.5 2.5 0 0 0 -5 0v5.5" /></svg>',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAuthStatusText(bool? auth) {
    String label;
    Color color;

    if (auth == true) {
      label = LocaleKeys.AuthRequired.tr();
      color = Colors.red;
    } else if (auth == false) {
      label = LocaleKeys.OpenAccess.tr();
      color = Colors.green;
    } else {
      label = LocaleKeys.AuthInfoUnavailable.tr();
      color = Colors.white70;
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InstancesTabBarDelegate extends SliverPersistentHeaderDelegate {
  _InstancesTabBarDelegate(this.controller);

  final TabController controller;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _InstancesTabSwitch(controller: controller);
  }

  @override
  bool shouldRebuild(_InstancesTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class _InstancesTabSwitch extends StatelessWidget {
  const _InstancesTabSwitch({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF191919),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _buildTabButton(context, 0, 'Kwiat'),
                _buildTabButton(context, 1, 'Hyper'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String label) {
    final bool isSelected = controller.index == index;

    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF333333) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            if (controller.index != index) {
              controller.animateTo(index);
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
