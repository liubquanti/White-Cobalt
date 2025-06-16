import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/settings.dart';
import 'storage.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsScreen({
    Key? key, 
    required this.settings, 
    required this.onSettingsChanged
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useLocalProcessing;
  late String _downloadDir;
  late String _downloadMode;
  late bool _disableMetadata;

  @override
  void initState() {
    super.initState();
    _useLocalProcessing = widget.settings.useLocalProcessing;
    _downloadDir = widget.settings.downloadDir;
    _downloadMode = widget.settings.downloadMode;
    _disableMetadata = widget.settings.disableMetadata;
  }
  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      useLocalProcessing: _useLocalProcessing,
      downloadDir: _downloadDir,
      downloadMode: _downloadMode,
      disableMetadata: _disableMetadata,
    );
    await prefs.setString('app_settings', jsonEncode(settings.toJson()));
    widget.onSettingsChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Expanded(
                      child: Row(
                      children: [
                        SizedBox(
                        width: 22,
                        height: 22,
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-cpu "><!----><path d="M5 5m0 1a1 1 0 0 1 1 -1h12a1 1 0 0 1 1 1v12a1 1 0 0 1 -1 1h-12a1 1 0 0 1 -1 -1z"></path><!----><path d="M9 9h6v6h-6z"></path><!----><path d="M3 10h2"></path><!----><path d="M3 14h2"></path><!----><path d="M10 3v2"></path><!----><path d="M14 3v2"></path><!----><path d="M21 10h-2"></path><!----><path d="M21 14h-2"></path><!----><path d="M14 21v-2"></path><!----><path d="M10 21v-2"></path><!----><!----><!----></svg>',
                        colorFilter: ColorFilter.mode(
                          _useLocalProcessing ? Colors.white : Colors.white38,
                          BlendMode.srcIn,
                        ),
                        ),),
                        const SizedBox(width: 12),
                        Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            'Local Processing',
                            style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _useLocalProcessing ? Colors.white : Colors.white54,
                            ),
                          ),
                          Text(
                            'Process media on the client-side',
                            style: TextStyle(
                            fontSize: 12,
                            color: _useLocalProcessing ? Colors.white70 : Colors.white38,
                            ),
                            softWrap: true,
                          ),
                          ],
                        ),
                        ),
                      ],
                      ),
                    ),
                    Switch(
                      value: _useLocalProcessing,
                      onChanged: (value) {
                      setState(() {
                        _useLocalProcessing = value;
                      });
                      _saveSettings();
                      },
                      activeColor: const Color(0xFFFFFFFF),
                      activeTrackColor: const Color(0xFF8a8a8a),
                      inactiveThumbColor: const Color(0xFFFFFFFF),
                      inactiveTrackColor: const Color(0xFF383838),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-file-download "><!----><path d="M14 3v4a1 1 0 0 0 1 1h4"></path><!----><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"></path><!----><path d="M12 17v-6"></path><!----><path d="M9.5 14.5l2.5 2.5l2.5 -2.5"></path><!----><!----><!----></svg>',
                              colorFilter: ColorFilter.mode(
                                _disableMetadata ? Colors.white : Colors.white38,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Metadata',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _disableMetadata ? Colors.white : Colors.white54,
                                  ),
                                ),
                                Text(
                                  'Remove title, artist, and other info from files',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _disableMetadata ? Colors.white70 : Colors.white38,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _disableMetadata,
                      onChanged: (value) {
                        setState(() {
                          _disableMetadata = value;
                        });
                        _saveSettings();
                      },
                      activeColor: const Color(0xFFFFFFFF),
                      activeTrackColor: const Color(0xFF8a8a8a),
                      inactiveThumbColor: const Color(0xFFFFFFFF),
                      inactiveTrackColor: const Color(0xFF383838),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Storage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                    width: 1.5,
                  ),
                  ),
                  child: InkWell(
                  borderRadius: BorderRadius.circular(9.5),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.05),
                  onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 250));
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StorageUsageScreen(
                      baseDir: _downloadDir,
                      ),
                    ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                    children: [
                      SizedBox(
                      width: 22,
                      height: 22,
                      child: SvgPicture.string(
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-database"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" /><path d="M4 6v6a8 3 0 0 0 16 0v-6" /><path d="M4 12v6a8 3 0 0 0 16 0v-6" /></svg>',
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                      'Storage Usage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      ),
                      const Spacer(),
                      const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      ),
                    ],
                    ),
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'White Cobalt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'A simple and efficient media downloader powered by Cobalt API.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLinkButton(
                          'GitHub',
                          Icons.code,
                          () => _launchURL('https://github.com/liubquanti/White-Cobalt'),
                        ),
                        const SizedBox(width: 10),
                        _buildLinkButton(
                          'Report Issue',
                          Icons.bug_report,
                          () => _launchURL('https://github.com/liubquanti/White-Cobalt/issues'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLinkButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: ElevatedButton(
        onPressed: onTap,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}