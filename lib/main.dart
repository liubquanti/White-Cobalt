import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light, 
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  await FlutterDownloader.initialize(
    debug: false
  );
  
  runApp(const CobaltApp());
}

class CobaltApp extends StatelessWidget {
  const CobaltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White Cobalt',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'NotoSansMono',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      home: const CobaltHomePage(),
    );
  }
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
  String? _baseUrl;
  bool _isLoading = false;
  bool _isDownloadInProgress = false;
  String _status = '';
  Map<String, dynamic>? _serverInfo;
  Map<String, dynamic>? _responseData;
  List<String> _servers = [];
  bool _urlFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
    _requestPermissions();
    _checkForSharedUrl();
    _urlController.addListener(_updateUrlFieldState);
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

  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _loadSavedServers() async {
    final prefs = await SharedPreferences.getInstance();
    final servers = prefs.getStringList('servers');
    if (servers != null && servers.isNotEmpty) {
      setState(() {
        _servers = servers;
        _baseUrl = servers.first;
      });
      _fetchServerInfo();
    } else {
      setState(() {
        _servers = [];
        _baseUrl = 'add_new';
        _status = 'No servers configured. Please add a Cobalt server.';
      });
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('servers', _servers);
  }

  Future<void> _fetchServerInfo() async {
    if (_baseUrl == null) {
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
      final response = await http.get(Uri.parse(_baseUrl!));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('cobalt') && 
            data['cobalt'].containsKey('version') && 
            data['cobalt'].containsKey('services')) {
          
          setState(() {
            _serverInfo = data;
            _status = 'Connected to Cobalt v${data['cobalt']['version']}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _status = 'Error: Not a valid Cobalt server';
            _isLoading = false;
            if (_servers.length > 1 && _baseUrl != _servers.first) {
              _baseUrl = _servers.first;
            }
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
  }

  Future<void> _addNewServer() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Add New Server',
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
              child: TextField(
                controller: _newServerController,
                decoration: InputDecoration(
                  hintText: 'Enter server URL',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 2.0, color: Colors.white),
                  ),
                  prefixIcon: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-server"><path d="M3 4m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z"></path><path d="M3 12m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z"></path><path d="M7 8l0 .01"></path><path d="M7 16l0 .01"></path></svg>',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.url,
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
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newServer = _newServerController.text.trim();
                if (newServer.isNotEmpty && !_servers.contains(newServer)) {
                  Navigator.of(context).pop();
                  _newServerController.clear();
                  
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
                      
                        setState(() {
                          _servers.add(newServer);
                          _baseUrl = newServer;
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
                  _newServerController.clear();
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
              child: const Text('add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.notification.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _processUrl() async {
    if (_baseUrl == null) {
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
      
      final response = await http.post(
        Uri.parse(_baseUrl!),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'videoQuality': 'max',
          'audioFormat': 'mp3',
          'filenameStyle': 'pretty',
          'downloadMode': 'auto',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseData = data;
          _isLoading = false;
          _status = 'Response received: ${data['status']}';
        });

        if (data['status'] == 'redirect' || data['status'] == 'tunnel') {
          final String downloadUrl = _fixServerUrl(data['url']);
          await _downloadFile(downloadUrl, data['filename']);
          
          // Reset download in progress after download starts
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              _isDownloadInProgress = false;
            });
          });
        } else if (data['status'] == 'picker') {
          setState(() {
            _isDownloadInProgress = false;
          });
        } else if (data['status'] == 'error') {
          setState(() {
            _status = 'Error: ${data['error']['code']}';
            _isDownloadInProgress = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isDownloadInProgress = false;
          _status = 'Request error: ${response.statusCode}';
        });
      }
    } catch (e) {
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
      Uri baseUri = Uri.parse(_baseUrl!);
      return url.replaceFirst(
        RegExp(r'http://localhost:\d+|http://127.0.0.1:\d+'),
        'http://${baseUri.host}:${baseUri.port}'
      );
    }
    return url;
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      const String downloadsPath = '/storage/emulated/0/Download';
      const cobaltDownloadsDir = '$downloadsPath/cobalt_downloads';
      final downloadsDir = Directory(cobaltDownloadsDir);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      setState(() {
        _status = 'Starting download...';
      });

      await FlutterDownloader.enqueue(
        url: url,
        savedDir: cobaltDownloadsDir,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      setState(() {
        _status = 'Download started';
      });
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
        _isDownloadInProgress = false;
      });
    }
  }
  
  Future<void> _downloadPickerItem(String url, String type) async {
    setState(() {
      _isDownloadInProgress = true;
    });
    
    try {
      final fixedUrl = _fixServerUrl(url);
      final extension = type == 'photo' ? '.jpg' : type == 'gif' ? '.gif' : '.mp4';
      final filename = 'cobalt_${DateTime.now().millisecondsSinceEpoch}$extension';
      await _downloadFile(fixedUrl, filename);
      
      // Reset download state after a small delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isDownloadInProgress = false;
        });
      });
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
        _isDownloadInProgress = false;
      });
    }
  }

  Future<void> _deleteServer(String server) async {
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
                'Are you sure you want to delete this server?\n\n$server',
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
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _servers.remove(server);
                  
                  if (_baseUrl == server) {
                    if (_servers.isNotEmpty) {
                      _baseUrl = _servers.first;
                      _fetchServerInfo();
                    } else {
                      _baseUrl = null;
                      _serverInfo = null;
                      _status = 'No servers configured. Please add a Cobalt server.';
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
              child: const Text('delete'),
            ),
          ],
        );
      },
    );
  }

  bool _isRealServerSelected() {
    return _baseUrl != null && _baseUrl != 'add_new';
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('White Cobalt'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/meowbalt/smile.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                    borderSide: BorderSide(width: 2.0, color: Colors.white),
                  ),
                  prefixIcon: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-file-download "><path d="M14 3v4a1 1 0 0 0 1 1h4"></path><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"></path><path d="M12 17v-6"></path><path d="M9.5 14.5l2.5 2.5l2.5 -2.5"></path></svg>',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                ),
                value: _servers.isNotEmpty ? _baseUrl : 'add_new',
                items: [
                  ..._servers.map((server) => DropdownMenuItem<String>(
                    value: server,
                    child: GestureDetector(
                      onLongPress: () {
                        Navigator.pop(context);
                        _deleteServer(server);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              server,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  DropdownMenuItem(
                    value: 'add_new',
                    child: Text(
                      'Add New Server',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _servers.isEmpty ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                onChanged: _isDownloadInProgress ? null : (value) async {
                  if (value == 'add_new') {
                    _addNewServer();
                    setState(() {
                      _baseUrl = 'add_new';
                    });
                  } else if (value != null && value != _baseUrl) {
                    setState(() {
                      _baseUrl = value;
                      _status = 'Connecting to server...';
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
                    width: 20,
                    height: 20,
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
                    hintText: 'paste the link here',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 2.0, color: Colors.white),
                    ),
                    prefixIcon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-link "><path d="M9 15l6 -6"></path><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"></path><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463"></path></svg>',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.url,
                )
              else if (_baseUrl == 'add_new')
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Please add a server first',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      borderSide: BorderSide(width: 1.0, color: Color(0xFF383838)),
                    ),
                    prefixIcon: SizedBox(
                      width: 24,
                      height: 24,
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

              if (_isRealServerSelected()) 
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: (_isLoading || _urlFieldEmpty || _isDownloadInProgress) ? null : _processUrl,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      backgroundColor: const Color(0xFF191919),
                      foregroundColor: (_urlFieldEmpty || _isDownloadInProgress) 
                        ? Colors.white38
                        : const Color(0xFFe1e1e1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(
                          color: (_urlFieldEmpty || _isDownloadInProgress)
                            ? const Color.fromRGBO(255, 255, 255, 0.05)
                            : const Color.fromRGBO(255, 255, 255, 0.08),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : const Text('download', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                )
              else if (_baseUrl == 'add_new')
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      backgroundColor: Colors.black45,
                      foregroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: const BorderSide(
                          color: Color.fromRGBO(255, 255, 255, 0.05),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text('download', style: TextStyle(fontSize: 14)),
                  ),
                ),

              const Divider(
                color: Color(0xFF383838),
                thickness: 1.0,
                height: 20,
              ),
              
              if (_serverInfo != null && _baseUrl != 'add_new')
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
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
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
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
                  ),
                )
              else if (_baseUrl == 'add_new')
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
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
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'No server selected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please select server first',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              
              else if ((_status.contains('Checking') || _status.contains('Connecting')) && _isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(_status, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _status.contains('Error') ? Icons.error_outline : Icons.info_outline,
                          color: _status.contains('Error') ? Colors.red : Colors.orange,
                          size: 16
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _status, 
                            style: TextStyle(
                              fontSize: 14, 
                              color: _status.contains('Error') ? Colors.red : Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
              if (_responseData != null && _responseData!['status'] == 'picker')
                Container(
                  height: 300,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _responseData!['picker'].length,
                    itemBuilder: (context, index) {
                      final item = _responseData!['picker'][index];
                      return Card(
                        color: const Color(0xFF191919),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: item['thumb'] != null
                            ? Image.network(
                                _fixServerUrl(item['thumb']),
                                width: 50,
                                errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                              )
                            : Icon(
                                item['type'] == 'photo'
                                  ? Icons.image
                                  : item['type'] == 'gif'
                                    ? Icons.gif
                                    : Icons.video_library,
                              ),
                          title: Text('${item['type']} #${index + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: _isDownloadInProgress ? null : () => _downloadPickerItem(item['url'], item['type']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              const Divider(
                color: Color(0xFF383838),
                thickness: 1.0,
                height: 20,
              ),

              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Container(
                  alignment: Alignment.center,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'NotoSansMono',
                      ),
                      children: [
                        const TextSpan(text: 'powered by '),
                        TextSpan(
                          text: 'cobalt',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontFamily: 'NotoSansMono',
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchURL('https://cobalt.tools/');
                            },
                        ),
                        const TextSpan(text: ', made by '),
                        TextSpan(
                          text: 'white heart',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontFamily: 'NotoSansMono',
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchURL('https://liubquanti.click/');
                            },
                        ),
                      ],
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

  @override
  void dispose() {
    _urlController.removeListener(_updateUrlFieldState);
    _urlController.dispose();
    _newServerController.dispose();
    super.dispose();
  }
}