import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:card_loading/card_loading.dart';

import '../config/server.dart';
import '../config/settings.dart';
import '../screens/settings.dart';
import '../screens/instances.dart';
import 'changelog.dart';
import '../services/share.dart';

class ChangelogEntry {
  final String version;
  final String title;
  final String date;
  final String content;
  final String? bannerFile;
  final String? bannerAlt;

  ChangelogEntry({
    required this.version,
    required this.title,
    required this.date,
    required this.content,
    this.bannerFile,
    this.bannerAlt,
  });
}

class CobaltHomePage extends StatefulWidget {
  const CobaltHomePage({super.key});

  @override
  State<CobaltHomePage> createState() => _CobaltHomePageState();
}

class _CobaltHomePageState extends State<CobaltHomePage> {
  static const platform = MethodChannel('com.whitecobalt.share/url');

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _newServerController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  DateTime? _lastProgressUpdate;
  String? _currentApiKey;
  bool _isLoading = false;
  bool _isDownloadInProgress = false;
  String _status = '';
  Map<String, dynamic>? _serverInfo;
  Map<String, dynamic>? _responseData;
  List<ServerConfig> _servers = [];
  bool _urlFieldEmpty = true;
  bool _useLocalProcessing = true;
  String _downloadMode = 'auto';
  AppSettings _appSettings = AppSettings();
  bool _showCopiedOnButton = false;
  List<ChangelogEntry> _changelogs = [];
  List<dynamic> _allChangelogFiles = [];
  int _loadedChangelogsCount = 0;
  bool _isLoadingMoreChangelogs = false;
  bool _isInitialLoadingChangelogs = true;

  String? _baseUrl;
  String? get baseUrl => _baseUrl;
  set baseUrl(String? value) {
    _baseUrl = value;

    SharedPreferences.getInstance().then((prefs) async {
      final selectedServerIndex = _servers.indexWhere((server) => server.url == _baseUrl);
      if (selectedServerIndex == -1) {
        return;
      }

      await prefs.setInt('selected_server_index', selectedServerIndex);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSavedServers();
    _requestPermissions();
    _checkForSharedUrl();
    _urlController.addListener(_updateUrlFieldState);
    _loadChangelogs();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');

    if (settingsJson != null) {
      setState(() {
        _appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
        _useLocalProcessing = _appSettings.useLocalProcessing;
        _downloadMode = _appSettings.downloadMode;
      });
    } else {
      setState(() {
        _appSettings = AppSettings();
        _useLocalProcessing = _appSettings.useLocalProcessing;
        _downloadMode = _appSettings.downloadMode;
      });
    }
  }

  void _onSettingsChanged(AppSettings newSettings) {
    setState(() {
      _appSettings = newSettings;
      _useLocalProcessing = _appSettings.useLocalProcessing;
      _downloadMode = _appSettings.downloadMode;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settings: _appSettings,
          onSettingsChanged: _onSettingsChanged,
        ),
      ),
    );
  }

  void _openInstancesList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstancesScreen(
          onServerAdded: (ServerConfig server) {
            setState(() {
              if (!_servers.any((s) => s.url == server.url)) {
                _servers.add(server);
                baseUrl = server.url;
                _currentApiKey = server.apiKey;
                _saveServers();
                _fetchServerInfo();
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _checkForSharedUrl() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final String? sharedUrl = await platform.invokeMethod('getSharedUrl');
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        _urlController.text = sharedUrl;

        setState(() {
          _urlFieldEmpty = false;
        });

        if (_isRealServerSelected()) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _processUrl();
          });
        } else {
          setState(() {
            _status = 'URL received from share, but please select a server first';
          });
        }
      }
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error checking shared URLs: ${e.message}';
      });
    }
  }

  Future<void> _loadSavedServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = prefs.getStringList('servers_config');
    final selectedServerIndex = prefs.getInt('selected_server_index');

    if (serversJson != null && serversJson.isNotEmpty) {
      setState(() {
        _servers = serversJson.map((s) => ServerConfig.fromJson(jsonDecode(s))).toList();
        baseUrl = selectedServerIndex != null && selectedServerIndex != -1
            ? _servers[selectedServerIndex].url
            : _servers.first.url;
        _currentApiKey = selectedServerIndex != null && selectedServerIndex != -1
            ? _servers[selectedServerIndex].apiKey
            : _servers.first.apiKey;
      });
      _fetchServerInfo();
    } else {
      setState(() {
        _servers = [];
        baseUrl = 'add_custom';
        _currentApiKey = null;
        _status = 'No servers configured. Please add a Cobalt server.';
      });
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = _servers.map((server) => jsonEncode(server.toJson())).toList();
    await prefs.setStringList('servers_config', serversJson);
  }

  Future<void> _loadChangelogs() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/imputnet/cobalt/contents/web/changelogs'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> files = jsonDecode(response.body);

        final mdFiles = files.where((file) => file['name'].toString().endsWith('.md')).toList();

        mdFiles.sort((a, b) {
          final versionA = a['name'].toString().replaceAll('.md', '');
          final versionB = b['name'].toString().replaceAll('.md', '');
          return _compareVersions(versionB, versionA);
        });

        setState(() {
          _allChangelogFiles = mdFiles;
        });

        await _loadNextChangelogs();
      }
    } catch (e) {
      print('Error loading changelogs: $e');
    }
  }

  Future<void> _loadNextChangelogs() async {
    if (_isLoadingMoreChangelogs) return;

    setState(() {
      _isLoadingMoreChangelogs = true;
    });

    try {
      final startIndex = _loadedChangelogsCount;
      final endIndex = (_loadedChangelogsCount + 3).clamp(0, _allChangelogFiles.length);
      final filesToLoad = _allChangelogFiles.sublist(startIndex, endIndex);

      final List<ChangelogEntry> newChangelogs = [];

      for (var file in filesToLoad) {
        final fileResponse = await http.get(
          Uri.parse(file['download_url']),
        );

        if (fileResponse.statusCode == 200) {
          final content = fileResponse.body;
          final changelog = _parseChangelog(file['name'], content);
          if (changelog != null) {
            newChangelogs.add(changelog);
          }
        }
      }

      setState(() {
        _changelogs.addAll(newChangelogs);
        _loadedChangelogsCount = endIndex;
        _isLoadingMoreChangelogs = false;
        _isInitialLoadingChangelogs = false;
      });
    } catch (e) {
      print('Error loading more changelogs: $e');
      setState(() {
        _isLoadingMoreChangelogs = false;
        _isInitialLoadingChangelogs = false;
      });
    }
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();

    for (int i = 0; i < aParts.length && i < bParts.length; i++) {
      if (aParts[i] != bParts[i]) {
        return aParts[i].compareTo(bParts[i]);
      }
    }
    return aParts.length.compareTo(bParts.length);
  }

  ChangelogEntry? _parseChangelog(String filename, String content) {
    try {
      final version = filename.replaceAll('.md', '');

      final lines = content.split('\n');
      if (lines.isEmpty || lines[0] != '---') return null;

      String title = '';
      String date = '';
      String changelogContent = '';
      String? bannerFile;
      String? bannerAlt;
      bool inFrontMatter = true;
      bool foundEndOfFrontMatter = false;
      bool inBannerSection = false;

      for (int i = 1; i < lines.length; i++) {
        if (lines[i] == '---' && inFrontMatter) {
          inFrontMatter = false;
          foundEndOfFrontMatter = true;
          continue;
        }

        if (inFrontMatter) {
          if (lines[i].startsWith('title:')) {
            title = lines[i].substring(6).trim().replaceAll('"', '');
          } else if (lines[i].startsWith('date:')) {
            date = lines[i].substring(5).trim().replaceAll('"', '');
          } else if (lines[i].startsWith('banner:')) {
            inBannerSection = true;
          } else if (inBannerSection && lines[i].trim().startsWith('file:')) {
            bannerFile = lines[i].split(':')[1].trim().replaceAll('"', '');
          } else if (inBannerSection && lines[i].trim().startsWith('alt:')) {
            bannerAlt = lines[i].split(':')[1].trim().replaceAll('"', '');
          } else if (inBannerSection && lines[i].trim().isEmpty) {
            inBannerSection = false;
          }
        } else if (foundEndOfFrontMatter) {
          changelogContent += '${lines[i]}\n';
        }
      }

      if (title.isNotEmpty && date.isNotEmpty) {
        return ChangelogEntry(
          version: version,
          title: title,
          date: date,
          content: changelogContent.trim(),
          bannerFile: bannerFile,
          bannerAlt: bannerAlt,
        );
      }
    } catch (e) {
      print('Error parsing changelog $filename: $e');
    }
    return null;
  }

  Future<void> _fetchServerInfo() async {
    if (baseUrl == null) {
      setState(() {
        _serverInfo = null;
        _status = 'No server selected';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _serverInfo = null;
      _status = 'Checking server...';
      _isLoading = true;
    });

    try {
      print('Fetching server info from: $baseUrl');
      final response = await http.get(Uri.parse(baseUrl!));
      print('Server info response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed server info: $data');

        if (data.containsKey('cobalt') &&
            data['cobalt'].containsKey('version') &&
            data['cobalt'].containsKey('services')) {
          setState(() {
            _serverInfo = data;
            _status = 'Connected to Cobalt v${data['cobalt']['version']}';
            _isLoading = false;
          });
          print('Successfully connected to Cobalt v${data['cobalt']['version']}');
        } else {
          print('Not a valid Cobalt server response: $data');
          setState(() {
            _status = 'Error: Not a valid Cobalt server';
            _isLoading = false;
            if (_servers.length > 1 && baseUrl != _servers.first) {
              baseUrl = _servers.first.url;
            }
          });
        }
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        setState(() {
          _status = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception while fetching server info: $e');
      setState(() {
        _status = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewServer() {
    _newServerController.clear();
    _apiKeyController.clear();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Add Custom Server',
            style: TextStyle(fontSize: 16),
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newServerController,
                  decoration: InputDecoration(
                    hintText: 'Enter server address',
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
                          '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-2"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /><path d="M11 8h6" /><path d="M11 16h6" /></svg>',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.url,
                  cursorColor: const Color(0xFFE1E1E1),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    hintText: 'API Key (optional)',
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
                final newServer = _newServerController.text.trim();
                final apiKey = _apiKeyController.text.trim();

                if (newServer.isNotEmpty && !_servers.any((s) => s.url == newServer)) {
                  Navigator.of(context).pop();

                  setState(() {
                    _status = 'Verifying server...';
                    _isLoading = true;
                  });

                  try {
                    final response = await http.get(Uri.parse(newServer));
                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);

                      if (data.containsKey('cobalt') &&
                          data['cobalt'].containsKey('version') &&
                          data['cobalt'].containsKey('services')) {
                        final serverConfig =
                            ServerConfig(newServer, apiKey.isNotEmpty ? apiKey : null);

                        setState(() {
                          _servers.add(serverConfig);
                          baseUrl = newServer;
                          _currentApiKey = apiKey.isNotEmpty ? apiKey : null;
                          _serverInfo = data;
                          _status = 'Connected to Cobalt v${data['cobalt']['version']}';
                          _isLoading = false;
                        });
                        _saveServers();
                      } else {
                        setState(() {
                          _status = 'Error: Not a valid Cobalt server';
                          _isLoading = false;
                        });
                      }
                    } else {
                      setState(() {
                        _status = 'Server error: ${response.statusCode}';
                        _isLoading = false;
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _status = 'Connection error: $e';
                      _isLoading = false;
                    });
                  }
                } else {
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

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.photos.request();
    await Permission.mediaLibrary.request();
    await Permission.audio.request();
  }

  Future<void> _processUrl() async {
    if (baseUrl == null) {
      setState(() {
        _status = 'Please add and select a server first';
      });
      return;
    }

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = 'Please enter a URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isDownloadInProgress = true;
      _status = 'Processing request...';
      _responseData = null;
    });

    try {
      Uri.parse(url);

      print('Sending request to: $baseUrl');
      final requestPayload = {
        'url': url,
        'videoQuality': _appSettings.videoQuality,
        'audioFormat': _appSettings.audioFormat,
        'audioBitrate': _appSettings.audioBitrate,
        'filenameStyle': 'classic',
        'downloadMode': _downloadMode,
        'localProcessing': _useLocalProcessing,
        'disableMetadata': _appSettings.disableMetadata,
        if (_appSettings.shareLinks) 'alwaysProxy': true,
      };

      print('Request payload: ${jsonEncode(requestPayload)}');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (_currentApiKey != null && _currentApiKey!.isNotEmpty) {
        headers['Authorization'] = 'Api-Key $_currentApiKey';
        print('Using API key: ${_currentApiKey!.substring(0, min(_currentApiKey!.length, 4))}...');
      }

      final response = await http.post(
        Uri.parse(baseUrl!),
        headers: headers,
        body: jsonEncode(requestPayload),
      );

      print('Server response status code: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseData = data;
          _isLoading = false;
          _status = 'Response received: ${data['status']}';
        });

        print('Parsed response data: $data');

        if (data['status'] == 'local-processing') {
          if (data.containsKey('tunnel') && data['tunnel'] is List && data['tunnel'].isNotEmpty) {
            setState(() {
              _status = 'Local processing: ${data['type']}';
            });

            final String tunnelUrl = data['tunnel'][0];
            final String filename = data['output']['filename'];

            print('Local processing tunnel URL: $tunnelUrl');
            print('Local processing filename: $filename');

            if (_appSettings.shareLinks) {
              String shareText = tunnelUrl;
              if (_appSettings.shareCopyToClipboard) {
                await Clipboard.setData(ClipboardData(text: shareText));
                setState(() {
                  _isDownloadInProgress = false;
                  _status = 'Link copied to clipboard';
                  _showCopiedOnButton = true;
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showCopiedOnButton = false;
                    });
                  }
                });
              } else {
                await NativeShare.shareText(shareText);
                setState(() {
                  _isDownloadInProgress = false;
                  _status = 'Link shared';
                });
              }
              return;
            } else {
              await _downloadFile(tunnelUrl, filename);
            }
          } else {
            setState(() {
              _status = 'Local processing error: Invalid response format';
              _isDownloadInProgress = false;
            });
          }
        } else if (data['status'] == 'redirect' || data['status'] == 'tunnel') {
          final String downloadUrl = _fixServerUrl(data['url']);
          print('Download URL: $downloadUrl');
          print('Filename: ${data['filename']}');

          if (_appSettings.shareLinks) {
            String shareText = downloadUrl;
            if (_appSettings.shareCopyToClipboard) {
              await Clipboard.setData(ClipboardData(text: shareText));
              setState(() {
                _isDownloadInProgress = false;
                _status = 'Link copied to clipboard';
                _showCopiedOnButton = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _showCopiedOnButton = false;
                  });
                }
              });
            } else {
              await NativeShare.shareText(shareText);
              setState(() {
                _isDownloadInProgress = false;
                _status = 'Link shared';
              });
            }
            return;
          } else {
            await _downloadFile(downloadUrl, data['filename']);
          }
        } else if (data['status'] == 'picker') {
          print('Picker options: ${data['picker'].length}');
          setState(() {
            _isDownloadInProgress = false;
          });
        } else if (data['status'] == 'error') {
          print('Error from server: ${data['error']}');

          if (data['error']['code'] == 'error.api.auth.key.missing') {
            setState(() {
              _status = 'API key required';
              _isDownloadInProgress = false;
            });
          } else {
            setState(() {
              _status = 'Error: ${data['error']['code']}';
              _isDownloadInProgress = false;
            });
          }
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          print('Error response: ${response.statusCode} - ${response.body}');

          setState(() {
            _responseData = errorData;
            _isLoading = false;
            _isDownloadInProgress = false;

            if (errorData['status'] == 'error' &&
                errorData['error'] != null &&
                errorData['error']['code'] == 'error.api.auth.key.missing') {
              _status = 'API key required';
            } else {
              _status = 'Request error: ${response.statusCode}';
            }
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _isDownloadInProgress = false;
            _status = 'Request error: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      print('Exception during request: $e');
      setState(() {
        _isLoading = false;
        _isDownloadInProgress = false;
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  String _fixServerUrl(String url) {
    Uri uri = Uri.parse(url);
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      Uri baseUri = Uri.parse(baseUrl!);
      return url.replaceFirst(RegExp(r'http://localhost:\d+|http://127.0.0.1:\d+'),
          'http://${baseUri.host}:${baseUri.port}');
    }
    return url;
  }

  String _getServiceName(Map<String, dynamic>? responseData, String filename, String url) {
    if (responseData != null) {
      if (responseData['service'] != null) {
        return responseData['service'].toString().toLowerCase();
      }
    }

    if (filename.contains('_')) {
      final serviceFromFilename = filename.split('_').first.toLowerCase();
      if (serviceFromFilename.isNotEmpty && serviceFromFilename != 'cobalt') {
        return serviceFromFilename;
      }
    }

    return _getServiceNameFromUrl(url);
  }

  String _getServiceNameFromUrl(String url) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return 'other';
    }

    String host = uri.host.toLowerCase();

    List<String> parts = host.split('.');
    if (parts.length > 1) {
      if (parts[0] == 'www' && parts.length > 2) {
        return parts[1];
      } else {
        return parts[parts.length - 2];
      }
    }

    return 'other';
  }

  String _getBaseDirByFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(extension)) {
      return '/storage/emulated/0/Pictures';
    } else if (['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', '3gp', 'wmv'].contains(extension)) {
      return '/storage/emulated/0/Movies';
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac', 'opus', 'wma'].contains(extension)) {
      return '/storage/emulated/0/Music';
    } else {
      return '/storage/emulated/0/Download';
    }
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final serviceName = _getServiceName(_responseData, filename, _urlController.text.trim());
      print('Detected service: $serviceName');

      String baseDir = _getBaseDirByFileType(filename);
      String cobaltDir = '$baseDir/Cobalt';
      String serviceDir = '$cobaltDir/$serviceName';

      print('Will try to save to: $serviceDir (based on file type)');

      try {
        Directory directory = Directory(cobaltDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          print('Created Cobalt directory: $cobaltDir');
        }

        directory = Directory(serviceDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          print('Created service directory: $serviceDir');
        }
      } catch (e) {
        print('Error creating directories: $e');
        serviceDir = baseDir;
      }

      setState(() {
        _status = 'Downloading: 0%';
      });

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$filename';

      print('Downloading to temp file: $tempFilePath');

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: tempDir.path,
        fileName: filename,
        showNotification: false,
        openFileFromNotification: false,
      );

      _trackDownloadProgress(taskId, (isComplete) async {
        if (isComplete) {
          try {
            final tempFile = File(tempFilePath);
            if (await tempFile.exists()) {
              final targetFile = File('$serviceDir/$filename');

              if (await targetFile.exists()) {
                await targetFile.delete();
              }

              await tempFile.copy(targetFile.path);
              print('File copied from $tempFilePath to ${targetFile.path}');

              try {
                print('Scanning file for media library: ${targetFile.path}');
                await MediaScanner.loadMedia(path: targetFile.path);
                print('Media scan complete');
              } catch (scanErr) {
                print('Error scanning media: $scanErr');
              }

              await tempFile.delete();
              print('Temporary file deleted');

              setState(() {
                _status = 'Download complete';
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() {
                      _isDownloadInProgress = false;
                    });
                  }
                });
              });
            } else {
              print('Temp file not found after download');
              setState(() {
                _status = 'Download failed: file not found';
                _isDownloadInProgress = false;
              });
            }
          } catch (e) {
            print('Error processing downloaded file: $e');
            setState(() {
              _status = 'Error processing file: $e';
              _isDownloadInProgress = false;
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
        _isDownloadInProgress = false;
      });
    }
  }

  void _trackDownloadProgress(String? taskId, Function(bool) onComplete) {
    if (taskId == null) return;

    _lastProgressUpdate = DateTime.now();

    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isDownloadInProgress) {
        timer.cancel();
        return;
      }

      if (_lastProgressUpdate != null &&
          DateTime.now().difference(_lastProgressUpdate!).inSeconds > 10) {
        setState(() {
          if (_status.contains('Downloading:')) {
            _status = '${_status} (still downloading...)';
          }
        });
      }

      try {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: "SELECT * FROM task WHERE task_id = '$taskId'");

        if (tasks == null || tasks.isEmpty) {
          timer.cancel();
          setState(() {
            _isDownloadInProgress = false;
          });
          return;
        }

        final task = tasks.first;
        setState(() {
          switch (task.status) {
            case DownloadTaskStatus.running:
              _status = 'Downloading: ${task.progress}%';
              _lastProgressUpdate = DateTime.now();
              break;
            case DownloadTaskStatus.complete:
              _status = 'Processing...';
              timer.cancel();
              onComplete(true);
              break;
            case DownloadTaskStatus.failed:
              _status = 'Download failed';
              _isDownloadInProgress = false;
              timer.cancel();
              onComplete(false);
              break;
            case DownloadTaskStatus.canceled:
              _status = 'Download canceled';
              _isDownloadInProgress = false;
              timer.cancel();
              onComplete(false);
              break;
            case DownloadTaskStatus.paused:
              _status = 'Download paused';
              break;
            default:
              _status = 'Download in queue';
          }
        });
      } catch (e) {
        print('Error tracking download: $e');
      }
    });
  }

  Future<void> _downloadPickerItem(String url, String type) async {
    setState(() {
      _isDownloadInProgress = true;
    });

    try {
      final fixedUrl = _fixServerUrl(url);
      final extension = type == 'photo'
          ? '.jpg'
          : type == 'gif'
              ? '.gif'
              : '.mp4';
      final filename = 'cobalt_${DateTime.now().millisecondsSinceEpoch}$extension';

      print('Downloading picker item: $type');
      print('Fixed URL: $fixedUrl');
      print('Filename: $filename');

      if (_appSettings.shareLinks) {
        String shareText = fixedUrl;
        if (_appSettings.shareCopyToClipboard) {
          await Clipboard.setData(ClipboardData(text: shareText));
          setState(() {
            _isDownloadInProgress = false;
            _status = 'Link copied to clipboard';
          });
        } else {
          await NativeShare.shareText(shareText);
          setState(() {
            _isDownloadInProgress = false;
            _status = 'Link shared';
          });
        }
        return;
      }

      final serviceName = _getServiceName(_responseData, filename, _urlController.text.trim());

      String baseDir = _getBaseDirByFileType(filename);
      String cobaltDir = '$baseDir/Cobalt';
      String serviceDir = '$cobaltDir/$serviceName';

      try {
        Directory directory = Directory(cobaltDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        directory = Directory(serviceDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } catch (e) {
        print('Error creating directories: $e');
        serviceDir = baseDir;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$filename';

      final taskId = await FlutterDownloader.enqueue(
        url: fixedUrl,
        savedDir: tempDir.path,
        fileName: filename,
        showNotification: false,
        openFileFromNotification: false,
      );

      _trackDownloadProgress(taskId, (isComplete) async {
        if (isComplete) {
          try {
            final tempFile = File(tempFilePath);
            if (await tempFile.exists()) {
              final targetFile = File('$serviceDir/$filename');
              if (await targetFile.exists()) {
                await targetFile.delete();
              }
              await tempFile.copy(targetFile.path);

              try {
                print('Scanning picker media file: ${targetFile.path}');
                await MediaScanner.loadMedia(path: targetFile.path);
                print('Media scan complete for picker item');
              } catch (scanErr) {
                print('Error scanning picker media: $scanErr');
              }

              await tempFile.delete();

              setState(() {
                _status = 'Download complete';
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() {
                      _isDownloadInProgress = false;
                    });
                  }
                });
              });
            } else {
              setState(() {
                _status = 'Download failed: file not found';
                _isDownloadInProgress = false;
              });
            }
          } catch (e) {
            setState(() {
              _status = 'Error processing file: $e';
              _isDownloadInProgress = false;
            });
          }
        }
      });
    } catch (e) {
      print('Error downloading picker item: $e');
      setState(() {
        _status = 'Download error: $e';
        _isDownloadInProgress = false;
      });
    }
  }

  Future<void> _deleteServer(String serverUrl) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Delete Server',
            style: TextStyle(fontSize: 16),
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Are you sure you want to delete this server?\n\n$serverUrl',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
              onPressed: () {
                setState(() {
                  int indexToRemove = _servers.indexWhere((s) => s.url == serverUrl);
                  if (indexToRemove >= 0) {
                    _servers.removeAt(indexToRemove);
                  }

                  if (baseUrl == serverUrl) {
                    if (_servers.isNotEmpty) {
                      baseUrl = _servers.first.url;
                      _currentApiKey = _servers.first.apiKey;
                      _fetchServerInfo();
                    } else {
                      baseUrl = 'add_custom';
                      _currentApiKey = null;
                      _serverInfo = null;
                      _status = 'No server selected';
                    }
                  }
                });
                _saveServers();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                backgroundColor: const Color(0xFF191919),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(
                    color: Color.fromRGBO(255, 255, 255, 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  bool _isRealServerSelected() {
    return baseUrl != null && baseUrl != 'add_custom';
  }

  Map<String, dynamic>? _getErrorDetails() {
    if (_responseData == null || _responseData!['status'] != 'error') {
      return null;
    }

    if (_responseData!['error'] != null) {
      print("Error details found: ${_responseData!['error']}");
      return _responseData!['error'];
    }
    return null;
  }

  void _updateUrlFieldState() {
    final newValue = _urlController.text.trim().isEmpty;
    if (newValue != _urlFieldEmpty) {
      setState(() {
        _urlFieldEmpty = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorDetails = _getErrorDetails();

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('White Cobalt'),
          centerTitle: true,
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-settings "><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z"><!----></path><!----><!----><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"><!----></path><!----><!--]--><!----><!----><!----><!----></svg>',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              onPressed: _openSettings,
              tooltip: 'Settings',
            ),
          ],
          leading: IconButton(
            icon: SvgPicture.string(
              '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-2"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /><path d="M11 8h6" /><path d="M11 16h6" /></svg>',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            onPressed: _openInstancesList,
            tooltip: 'Servers',
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SvgPicture.asset(
                'assets/heart/Heart Meowbalt.svg',
                height: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.5, color: Color(0xFF383838)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.5, color: Color(0xFFB1B1B1)),
                  ),
                  prefixIcon: SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-file-download "><path d="M14 3v4a1 1 0 0 0 1 1h4"></path><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"></path><path d="M12 17v-6"></path><path d="M9.5 14.5l2.5 2.5l2.5 -2.5"></path></svg>',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                ),
                value: _servers.isNotEmpty ? baseUrl : 'add_custom',
                items: [
                  ..._servers.map((server) => DropdownMenuItem<String>(
                        value: server.url,
                        child: GestureDetector(
                          onLongPress: () {
                            Navigator.pop(context);
                            _deleteServer(server.url);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  server.url,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (server.apiKey != null && server.apiKey!.isNotEmpty)
                                const SizedBox(width: 4),
                              if (server.apiKey != null && server.apiKey!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'KEY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )),
                  DropdownMenuItem(
                    value: 'add_custom',
                    child: Text(
                      'Add Custom Server',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _servers.isEmpty ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                onChanged: _isDownloadInProgress
                    ? null
                    : (value) async {
                        if (value == 'add_custom') {
                          _addNewServer();
                          setState(() {
                            baseUrl = 'add_custom';
                            _responseData = null;
                          });
                        } else if (value != null && value != baseUrl) {
                          final selectedServer = _servers.firstWhere((s) => s.url == value);
                          setState(() {
                            baseUrl = value;
                            _currentApiKey = selectedServer.apiKey;
                            _status = 'Connecting to server...';
                            _responseData = null;
                          });
                          await _fetchServerInfo();
                        }
                      },
                menuMaxHeight: 500,
                isExpanded: true,
                isDense: true,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-selector "><path d="M8 9l4 -4l4 4"></path><path d="M16 15l-4 4l-4 -4"></path></svg>',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
              ),
              const SizedBox(height: 10),
              if (_isRealServerSelected())
                TextField(
                  controller: _urlController,
                  enabled: !_isDownloadInProgress,
                  decoration: InputDecoration(
                    hintText: 'Paste the link here',
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.5, color: Color(0xFF383838)),
                    ),
                    disabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.5, color: Color(0xFF383838)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.5, color: Color(0xFFB1B1B1)),
                    ),
                    prefixIcon: SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-link "><path d="M9 15l6 -6"></path><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"></path><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l .524 -.463"></path></svg>',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: SvgPicture.string(
                              '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-backspace"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M20 6a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-11l-5 -5a1.5 1.5 0 0 1 0 -2l5 -5z" /><path d="M12 10l4 4m0 -4l-4 4" /></svg>',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                            ),
                            onPressed: _isDownloadInProgress
                                ? null
                                : () {
                                    _urlController.clear();
                                  },
                          )
                        : IconButton(
                            icon: SvgPicture.string(
                              '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-clipboard-text"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z" /><path d="M9 12h6" /><path d="M9 16h6" /></svg>',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                            ),
                            tooltip: 'Paste from clipboard',
                            onPressed: _isDownloadInProgress
                                ? null
                                : () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data != null &&
                                        data.text != null &&
                                        data.text!.isNotEmpty) {
                                      _urlController.text = data.text!;
                                    }
                                  },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                  ),
                  cursorColor: const Color(0xFFE1E1E1),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.url,
                )
              else if (baseUrl == 'add_custom')
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Please add a server first',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                    ),
                    prefixIcon: SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-link "><path d="M9 15l6 -6"></path><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"></path><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l .524 -.463"></path></svg>',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(Colors.white30, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black45,
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.white38),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_isLoading ||
                            _urlFieldEmpty ||
                            _isDownloadInProgress ||
                            !_isRealServerSelected())
                        ? null
                        : _processUrl,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 44),
                      backgroundColor: const Color(0xFF191919),
                      foregroundColor:
                          (_urlFieldEmpty || _isDownloadInProgress || !_isRealServerSelected())
                              ? Colors.white38
                              : const Color(0xFFe1e1e1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(
                          color:
                              (_urlFieldEmpty || _isDownloadInProgress || !_isRealServerSelected())
                                  ? const Color.fromRGBO(255, 255, 255, 0.05)
                                  : const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 80,
                            height: 20,
                            child: CardLoading(
                              height: 16,
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                              width: 80,
                              cardLoadingTheme: CardLoadingTheme(
                                colorOne: Color(0xFF383838),
                                colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                              ),
                            ),
                          )
                        : _isDownloadInProgress
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _status.contains('Downloading:')
                                        ? _status.substring(_status.indexOf(':') + 1).trim()
                                        : _status,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _status.contains('Complete')
                                          ? Colors.green
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _showCopiedOnButton
                                    ? 'Copied!'
                                    : (_appSettings.shareLinks ? 'Share' : 'Download'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF191919),
                  border: Border.all(
                    color: Color.fromRGBO(255, 255, 255, _isRealServerSelected() ? 0.08 : 0.04),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _buildModeButton('auto', '✨ Auto'),
                    _buildModeButton('audio', '🎶 Audio'),
                    _buildModeButton('mute', '🔇 Mute'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(
                color: Color(0xFF383838),
                thickness: 1.0,
                height: 1,
              ),
              const SizedBox(height: 10),
              if (_responseData != null && _responseData!['status'] == 'picker') ...[
                Column(
                  children: List.generate(_responseData!['picker'].length, (index) {
                    final item = _responseData!['picker'][index];
                    return Card(
                      color: const Color(0xFF191919),
                      margin: EdgeInsets.only(
                        top: index == 0 ? 0 : 5,
                        bottom: index == _responseData!['picker'].length - 1 ? 0 : 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: const BorderSide(
                          color: Color.fromRGBO(255, 255, 255, 0.05),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        child: Row(
                          children: [
                            if (item['thumb'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  _fixServerUrl(item['thumb']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: SvgPicture.string(
                                      '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-photo-off"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 8h.01" /><path d="M7 3h11a3 3 0 0 1 3 3v11m-.856 3.099a2.991 2.991 0 0 1 -2.144 .901h-12a3 3 0 0 1 -3 -3v-12c0 -.845 .349 -1.608 .91 -2.153" /><path d="M3 16l5 -5c.928 -.893 2.072 -.893 3 0l5 5" /><path d="M16.33 12.338c.574 -.054 1.155 .166 1.67 .662l3 3" /><path d="M3 3l18 18" /></svg>',
                                      width: 22,
                                      height: 22,
                                      colorFilter:
                                          const ColorFilter.mode(Colors.white38, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  item['type'] == 'photo'
                                      ? Icons.image
                                      : item['type'] == 'gif'
                                          ? Icons.gif
                                          : Icons.video_library,
                                  size: 32,
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${item['type']} #${index + 1}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: SvgPicture.string(
                                '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-download"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" /><path d="M7 11l5 5l5 -5" /><path d="M12 4l0 12" /></svg>',
                                width: 22,
                                height: 22,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                              onPressed: _isDownloadInProgress
                                  ? null
                                  : () => _downloadPickerItem(item['url'], item['type']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Color(0xFF383838),
                  thickness: 1.0,
                  height: 1,
                ),
                const SizedBox(height: 10),
              ],
              if (errorDetails != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.string(
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-exclamation-circle"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M12 9v4" /><path d="M12 16v.01" /></svg>',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Server Error',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${errorDetails['code']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (errorDetails['message'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            '${errorDetails['message']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else if ((_status.contains('Checking') || _status.contains('Connecting')) &&
                  _isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CardLoading(
                            height: 16,
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            width: 16,
                            cardLoadingTheme: CardLoadingTheme(
                              colorOne: Color(0xFF383838),
                              colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                            ),
                          ),
                          SizedBox(width: 10),
                          CardLoading(
                            height: 16,
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            width: 150,
                            cardLoadingTheme: CardLoadingTheme(
                              colorOne: Color(0xFF383838),
                              colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      CardLoading(
                        height: 15,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        width: 150,
                        cardLoadingTheme: CardLoadingTheme(
                          colorOne: Color(0xFF383838),
                          colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_serverInfo != null && baseUrl != 'add_custom')
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.string(
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-circle-check"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M9 12l2 2l4 -4" /></svg>',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cobalt v${_serverInfo!['cobalt']['version']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supported services: ${_serverInfo!['cobalt']['services'].length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (baseUrl == 'add_custom')
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.string(
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-server-2"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /><path d="M11 8h6" /><path d="M11 16h6" /></svg>',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'No server selected',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Please select server first',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (_status.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _status.contains('Error')
                              ? SvgPicture.string(
                                  '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-exclamation-circle"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M12 9v4" /><path d="M12 16v.01" /></svg>',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                                )
                              : SvgPicture.string(
                                  '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-info-circle"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 9h.01" /><path d="M11 12h1v4h1" /></svg>',
                                  width: 16,
                                  height: 16,
                                  colorFilter:
                                      const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                                ),
                          const SizedBox(width: 8),
                          Text(
                            _status.contains('Error') ? 'Error' : 'Status',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _status,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (_appSettings.showChangelogs) ...[
                const Divider(
                  color: Color(0xFF383838),
                  thickness: 1.0,
                  height: 1,
                ),
                const SizedBox(height: 10),
                if (_isInitialLoadingChangelogs) ...[
                  _buildChangelogSkeleton(),
                  const SizedBox(height: 10),
                  _buildChangelogSkeleton(),
                  const SizedBox(height: 10),
                  _buildChangelogSkeleton(),
                ] else if (_changelogs.isNotEmpty) ...[
                  ..._changelogs
                      .map(
                        (changelog) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Material(
                              color: const Color(0xFF1a1a1a),
                              borderRadius: BorderRadius.circular(11.0),
                              child: InkWell(
                                onTap: () async {
                                  await Future.delayed(const Duration(milliseconds: 250));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChangelogDetailScreen(changelog: changelog),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(11.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11.0),
                                    border: Border.all(
                                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (changelog.bannerFile != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(11.0),
                                            topRight: Radius.circular(11.0),
                                          ),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                'https://github.com/imputnet/cobalt/raw/main/web/static/update-banners/${changelog.bannerFile}',
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    height: 120,
                                                    width: double.infinity,
                                                    decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.white],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'v${changelog.version}',
                                                        style: const TextStyle(
                                                          fontSize: 24,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const CardLoading(
                                                    height: 120,
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(11.0),
                                                      topRight: Radius.circular(11.0),
                                                    ),
                                                    cardLoadingTheme: CardLoadingTheme(
                                                      colorOne: Color(0xFF2a2a2a),
                                                      colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'API Update',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'v${changelog.version}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  changelog.date,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              changelog.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    changelog.content.length > 150
                                                        ? '${changelog.content.substring(0, 150)}...'
                                                        : changelog.content,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
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
                            )),
                      )
                      .toList(),
                  if (_loadedChangelogsCount < _allChangelogFiles.length)
                    Material(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(11.0),
                      child: InkWell(
                        onTap: _isLoadingMoreChangelogs ? null : _loadNextChangelogs,
                        borderRadius: BorderRadius.circular(11.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11.0),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.05),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: _isLoadingMoreChangelogs
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        year2023: false,
                                        color: Colors.white,
                                        backgroundColor: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Load more',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                ],
              ],
              const SizedBox(height: 16),
            ]),
          ),
        ));
  }

  Widget _buildChangelogSkeleton() {
    return Material(
      color: const Color(0xFF1a1a1a),
      borderRadius: BorderRadius.circular(11.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11.0),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
            width: 1.5,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardLoading(
              height: 120,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11.0),
                topRight: Radius.circular(11.0),
              ),
              cardLoadingTheme: CardLoadingTheme(
                colorOne: Color(0xFF2a2a2a),
                colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CardLoading(
                        height: 14,
                        width: 60,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        cardLoadingTheme: CardLoadingTheme(
                          colorOne: Color(0xFF383838),
                          colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                      ),
                      CardLoading(
                        height: 12,
                        width: 80,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        cardLoadingTheme: CardLoadingTheme(
                          colorOne: Color(0xFF383838),
                          colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  CardLoading(
                    height: 13,
                    width: 200,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    cardLoadingTheme: CardLoadingTheme(
                      colorOne: Color(0xFF383838),
                      colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                    ),
                  ),
                  SizedBox(height: 10),
                  CardLoading(
                    height: 12,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    cardLoadingTheme: CardLoadingTheme(
                      colorOne: Color(0xFF383838),
                      colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                    ),
                  ),
                  SizedBox(height: 6),
                  CardLoading(
                    height: 12,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    cardLoadingTheme: CardLoadingTheme(
                      colorOne: Color(0xFF383838),
                      colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                    ),
                  ),
                  SizedBox(height: 6),
                  CardLoading(
                    height: 12,
                    width: 250,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    cardLoadingTheme: CardLoadingTheme(
                      colorOne: Color(0xFF383838),
                      colorTwo: Color.fromRGBO(255, 255, 255, 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.removeListener(_updateUrlFieldState);
    _urlController.dispose();
    _newServerController.dispose();
    super.dispose();
  }

  Widget _buildModeButton(String mode, String label) {
    final bool isSelected = _downloadMode == mode;
    final bool isEnabled = _isRealServerSelected() && !_isDownloadInProgress;

    return Expanded(
      child: Material(
        color: isSelected && isEnabled ? const Color(0xFF333333) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: isEnabled
              ? () {
                  setState(() {
                    _downloadMode = mode;
                  });

                  _appSettings.downloadMode = mode;
                  _saveDownloadModeSetting();
                }
              : null,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected && isEnabled ? FontWeight.bold : FontWeight.normal,
                color: isEnabled ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveDownloadModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(_appSettings.toJson()));
  }
}
