import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/instance.dart';
import '../services/instances.dart';
import '../config/server.dart';

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
  List<CobaltInstance> _instances = [];
  String _error = '';
  final TextEditingController _apiKeyController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final instances = await InstancesService.fetchInstances();
      
      instances.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }
        return b.score.compareTo(a.score);
      });
      
      setState(() {
        _instances = instances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load instances: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addServerWithConfirmation(CobaltInstance instance) async {
    _apiKeyController.clear();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Add ${instance.api}',
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
                'Server: ${instance.apiUrl}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              if (instance.version != null) 
                Text(
                  'Version: ${instance.version}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              Text(
                'Score: ${instance.score}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                'Services: ${instance.servicesCount}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'API Key (optional):',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: 'Enter API Key if required',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                Navigator.of(context).pop();
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                final apiKey = _apiKeyController.text.trim();
                final server = ServerConfig(
                  instance.apiUrl,
                  apiKey.isNotEmpty ? apiKey : null,
                );
                
                widget.onServerAdded(server);
                
                if (mounted) {
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
              child: const Text('Add'),
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
        title: const Text('Cobalt Servers'),
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
          color: Colors.white,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInstances,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_instances.isEmpty) {
      return const Center(
        child: Text('No servers found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _instances.length,
      itemBuilder: (context, index) {
        final instance = _instances[index];
        return _buildInstanceCard(instance);
      },
    );
  }

  Widget _buildInstanceCard(CobaltInstance instance) {
    final isOnline = instance.isOnline;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF191919),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: Color.fromRGBO(255, 255, 255, isOnline ? 0.08 : 0.04),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: isOnline ? () async {
          await Future.delayed(const Duration(milliseconds: 250));
          await _addServerWithConfirmation(instance);
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.string(
                    '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-2"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /><path d="M11 8h6" /><path d="M11 16h6" /></svg>',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(isOnline ? Colors.green : Colors.red, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instance.api,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(instance.score),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${instance.score}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Protocol: ${instance.protocol}',
                        style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.white70 : Colors.white38,
                        ),
                      ),
                      if (instance.version != null)
                        Text(
                        'Version: ${instance.version}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.white70 : Colors.white38,
                        ),
                        ),
                      Text(
                        'Services: ${instance.servicesCount}',
                        style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.white70 : Colors.white38,
                        ),
                      ),
                      ],
                    ),
                    ),
                    if (instance.frontend != "None")
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
                  ],
              ),
            ],
          ),
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
}