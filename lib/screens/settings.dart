import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/settings.dart';
import 'storage.dart';
import 'advanced.dart';
import 'about.dart';

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
  late bool _shareLinks;
  late bool _shareCopyToClipboard;
  late String _audioBitrate;
  late String _audioFormat;
  late String _videoQuality;
  late bool _showChangelogs;

  @override
  void initState() {
    super.initState();
    _useLocalProcessing = widget.settings.useLocalProcessing;
    _downloadDir = widget.settings.downloadDir;
    _downloadMode = widget.settings.downloadMode;
    _disableMetadata = widget.settings.disableMetadata;
    _shareLinks = widget.settings.shareLinks;
    _shareCopyToClipboard = widget.settings.shareCopyToClipboard;
    _audioBitrate = widget.settings.audioBitrate;
    _audioFormat = widget.settings.audioFormat;
    _videoQuality = widget.settings.videoQuality;
    _showChangelogs = widget.settings.showChangelogs;
  }
  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      useLocalProcessing: _useLocalProcessing,
      downloadDir: _downloadDir,
      downloadMode: _downloadMode,
      disableMetadata: _disableMetadata,
      shareLinks: _shareLinks,
      shareCopyToClipboard: _shareCopyToClipboard,
      audioBitrate: _audioBitrate,
      audioFormat: _audioFormat,
      videoQuality: _videoQuality,
      showChangelogs: _showChangelogs,
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
          padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Downloads',
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
                              '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-share"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M18 6m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M18 18m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M8.7 10.7l6.6 -3.4" /><path d="M8.7 13.3l6.6 3.4" /></svg>',
                              colorFilter: ColorFilter.mode(
                                _shareLinks ? Colors.white : Colors.white38,
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
                                  'Share Links',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _shareLinks ? Colors.white : Colors.white54,
                                  ),
                                ),
                                Text(
                                  'Share links instead of downloading files',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _shareLinks ? Colors.white70 : Colors.white38,
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
                      value: _shareLinks,
                      onChanged: (value) {
                        setState(() {
                          _shareLinks = value;
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
                          builder: (context) => AdvancedSettingsScreen(
                            disableMetadata: _disableMetadata,
                            onChanged: (value) {
                              setState(() {
                                _disableMetadata = value;
                              });
                              _saveSettings();
                            },
                            shareCopyToClipboard: _shareCopyToClipboard,
                            onShareCopyChanged: (value) {
                              setState(() {
                                _shareCopyToClipboard = value;
                              });
                              _saveSettings();
                            },
                            audioBitrate: _audioBitrate,
                            audioFormat: _audioFormat,
                            videoQuality: _videoQuality,
                            onAudioBitrateChanged: (v) {
                              setState(() => _audioBitrate = v);
                              _saveSettings();
                            },
                            onAudioFormatChanged: (v) {
                              setState(() => _audioFormat = v);
                              _saveSettings();
                            },
                            onVideoQualityChanged: (v) {
                              setState(() => _videoQuality = v);
                              _saveSettings();
                            },
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
                              '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-settings-cog"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12.003 21c-.732 .001 -1.465 -.438 -1.678 -1.317a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c.886 .215 1.325 .957 1.318 1.694" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /><path d="M19.001 19m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M19.001 15.5v1.5" /><path d="M19.001 21v1.5" /><path d="M22.032 17.25l-1.299 .75" /><path d="M17.27 20l-1.3 .75" /><path d="M15.97 17.25l1.3 .75" /><path d="M20.733 20l1.3 .75" /></svg>',
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Advanced Settings',
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
                'Interface',
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
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-git-cherry-pick"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M7 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M7 3v6" /><path d="M7 15v6" /><path d="M13 7h2.5l1.5 5l-1.5 5h-2.5" /><path d="M17 12h3" /></svg>',
                              colorFilter: ColorFilter.mode(
                                _showChangelogs ? Colors.white : Colors.white38,
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
                                  'Show Changelogs',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _showChangelogs ? Colors.white : Colors.white54,
                                  ),
                                ),
                                Text(
                                  'Display API changelogs on home screen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _showChangelogs ? Colors.white70 : Colors.white38,
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
                      value: _showChangelogs,
                      onChanged: (value) {
                        setState(() {
                          _showChangelogs = value;
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
                      builder: (context) => AboutScreen(
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
                        '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-info-circle"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 9h.01" /><path d="M11 12h1v4h1" /></svg>',
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                      'App Information',
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
            ],
          ),
        ),
      ),
    );
  }
}