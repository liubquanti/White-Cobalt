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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:filesize/filesize.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  print('Download task ($id) is in status ($status) and progress ($progress)');
}

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
  
  FlutterDownloader.registerCallback(downloadCallback);
  
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

class ServerConfig {
  final String url;
  final String? apiKey;

  ServerConfig(this.url, this.apiKey);

  Map<String, dynamic> toJson() => {
    'url': url,
    'apiKey': apiKey,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      json['url'] as String,
      json['apiKey'] as String?,
    );
  }
}

class AppSettings {
  bool useLocalProcessing;
  String downloadDir;
  String downloadMode;
  bool disableMetadata;

  AppSettings({
    this.useLocalProcessing = true,
    this.downloadDir = '/storage/emulated/0/Download/Cobalt',
    this.downloadMode = 'auto',
    this.disableMetadata = false,
  });

  Map<String, dynamic> toJson() => {
    'useLocalProcessing': useLocalProcessing,
    'downloadDir': downloadDir,
    'downloadMode': downloadMode,
    'disableMetadata': disableMetadata,
  };
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useLocalProcessing: json['useLocalProcessing'] ?? true,
      downloadDir: json['downloadDir'] ?? '/storage/emulated/0/Download/Cobalt',
      downloadMode: json['downloadMode'] ?? 'auto',
      disableMetadata: json['disableMetadata'] ?? false,
    );
  }
}

class _CobaltHomePageState extends State<CobaltHomePage> {
  static const platform = MethodChannel('com.whitecobalt.share/url');
  
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _newServerController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  
  DateTime? _lastProgressUpdate;
  String? _baseUrl;
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
  late AppSettings _appSettings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSavedServers();
    _requestPermissions();
    _checkForSharedUrl();
    _urlController.addListener(_updateUrlFieldState);
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
    final serversJson = prefs.getStringList('servers_config');
    
    if (serversJson != null && serversJson.isNotEmpty) {
      setState(() {
        _servers = serversJson
            .map((s) => ServerConfig.fromJson(jsonDecode(s)))
            .toList();
        _baseUrl = _servers.first.url;
        _currentApiKey = _servers.first.apiKey;
      });
      _fetchServerInfo();
    } else {
      setState(() {
        _servers = [];
        _baseUrl = 'add_new';
        _currentApiKey = null;
        _status = 'No servers configured. Please add a Cobalt server.';
      });
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = _servers
        .map((server) => jsonEncode(server.toJson()))
        .toList();
    await prefs.setStringList('servers_config', serversJson);
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
      print('Fetching server info from: $_baseUrl');
      final response = await http.get(Uri.parse(_baseUrl!));
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
            if (_servers.length > 1 && _baseUrl != _servers.first) {
              _baseUrl = _servers.first.url;
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
                      width: 24,
                      height: 24,
                      child: Center(
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-key"><path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.068l-2.643 2.643a2.877 2.877 0 0 1 -4.068 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l6.558 -6.558l-.301 -.301a2.877 2.877 0 0 1 0 -4.068l2.643 -2.643a2.877 2.877 0 0 1 4.068 0z"></path><path d="M15 9h.01"></path></svg>',
                          width: 20,
                          height: 20,
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
              child: const Text('cancel'),
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
                      
                        final serverConfig = ServerConfig(
                          newServer, 
                          apiKey.isNotEmpty ? apiKey : null
                        );
                        
                        setState(() {
                          _servers.add(serverConfig);
                          _baseUrl = newServer;
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
              child: const Text('add'),
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
      
      print('Sending request to: $_baseUrl');
        final requestPayload = {
        'url': url,
        'videoQuality': 'max',
        'audioFormat': 'mp3',
        'filenameStyle': 'classic',
        'downloadMode': _downloadMode,
        'localProcessing': _useLocalProcessing,
        'disableMetadata': _appSettings.disableMetadata,
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
        Uri.parse(_baseUrl!),
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
            print('Local processing filename: $filename');            await _downloadFile(tunnelUrl, filename);
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
            await _downloadFile(downloadUrl, data['filename']);
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
      Uri baseUri = Uri.parse(_baseUrl!);
      return url.replaceFirst(
        RegExp(r'http://localhost:\d+|http://127.0.0.1:\d+'),
        'http://${baseUri.host}:${baseUri.port}'
      );
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
    if (serviceFromFilename.isNotEmpty) {
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

Future<void> _downloadFile(String url, String filename) async {
  try {
    final serviceName = _getServiceName(_responseData, filename, _urlController.text.trim());
    print('Detected service: $serviceName');
    
    String baseDir = '/storage/emulated/0/Download';
    String cobaltDir = '$baseDir/Cobalt';
    String serviceDir = '$cobaltDir/$serviceName';
    
    print('Will try to save to: $serviceDir');
    
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
        query: "SELECT * FROM task WHERE task_id = '$taskId'"
      );
      
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
      final extension = type == 'photo' ? '.jpg' : type == 'gif' ? '.gif' : '.mp4';
      final filename = 'cobalt_${DateTime.now().millisecondsSinceEpoch}$extension';
      
      print('Downloading picker item: $type');
      print('Fixed URL: $fixedUrl');
      print('Filename: $filename');
      
      final serviceName = _getServiceName(_responseData, filename, _urlController.text.trim());
      
      String baseDir = '/storage/emulated/0/Download';
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
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  int indexToRemove = _servers.indexWhere((s) => s.url == serverUrl);
                  if (indexToRemove >= 0) {
                    _servers.removeAt(indexToRemove);
                  }
                  
                  if (_baseUrl == serverUrl) {
                    if (_servers.isNotEmpty) {
                      _baseUrl = _servers.first.url;
                      _currentApiKey = _servers.first.apiKey;
                      _fetchServerInfo();
                    } else {
                      _baseUrl = 'add_new';
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
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            const Icon(
                              Icons.key,
                              size: 16,
                              color: Colors.green,
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
                    final selectedServer = _servers.firstWhere((s) => s.url == value);
                    setState(() {
                      _baseUrl = value;
                      _currentApiKey = selectedServer.apiKey;
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
                      width: 24,
                      height: 24,
                      child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-link "><path d="M9 15l6 -6"></path><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"></path><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l .524 -.463"></path></svg>',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                      ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    ),
                    cursorColor: const Color(0xFFE1E1E1),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: ElevatedButton(
                        onPressed: (_isLoading || _urlFieldEmpty || _isDownloadInProgress) ? null : _processUrl,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
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
                          : _isDownloadInProgress
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 Text(
                                    _status.contains('Downloading:') ? 
                                      _status.substring(_status.indexOf(':') + 1).trim() : 
                                      _status,
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.bold,
                                      color: _status.contains('Complete') ? Colors.green : Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('download', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: const Color(0xFF191919),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildModeButton('auto', '✨ auto'),
                            _buildModeButton('audio', '🎶 audio'),
                            _buildModeButton('mute', '🔇 mute'),
                          ],
                        ),
                      ),
                    ),
                  ],
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
              
              if (errorDetails != null)
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
                    const Row(
                      children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
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
                      style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      ),
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
                  ),
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
                            Icon(Icons.dns, color: Colors.orange, size: 16),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_status, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else if (_status.isNotEmpty)
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
                      Icon(
                        _status.contains('Error')
                          ? Icons.error
                          : Icons.info,
                        color: _status.contains('Error')
                          ? Colors.red
                          : Colors.orange,
                        size: 16,
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
                      style: const TextStyle(
                      fontSize: 12,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
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
                        const TextSpan(text: 'illustrated by '),
                        TextSpan(
                          text: 'ffastffox',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontFamily: 'NotoSansMono',
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchURL('https://www.instagram.com/ffastffox/');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
          ),
        ),
      ));

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
    
    return Expanded(
      child: InkWell(
        onTap: _isDownloadInProgress ? null : () {
          setState(() {
            _downloadMode = mode;
          });
          
          _appSettings.downloadMode = mode;
          _saveDownloadModeSetting();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: isSelected ? const Color(0xFF333333) : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),
              
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
                        width: 20,
                        height: 20,
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 8l-4 4l4 4"></path><path d="M17 8l4 4l-4 4"></path><path d="M14 4l-4 16"></path></svg>',
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
                          const SizedBox(height: 4),
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
                ),              ),

              const SizedBox(height: 16),
              
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
                            width: 20,
                            height: 20,
                            child: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a3 3 0 0 0-3 3v1H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-3V5a3 3 0 0 0-3-3"></path><path d="M9 14v-4h6v4"></path><path d="M12 14v4"></path></svg>',
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
                                  'Disable Metadata',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _disableMetadata ? Colors.white : Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 4),
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

              const SizedBox(height: 20),
              
              const Text(
                'Storage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
                const SizedBox(height: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                    children: [
                      SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><path d="M5.8 11a6 6 0 0 1 6.2 -6"></path><path d="M12 5a6 6 0 0 1 6 6"></path><path d="M12 12l3.5 -1.5"></path></svg>',
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
              const SizedBox(height: 20),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
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
                    const SizedBox(height: 8),
                    const Text(
                      'A simple and efficient media downloader powered by Cobalt API.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLinkButton(
                          'GitHub',
                          Icons.code,
                          () => _launchURL('https://github.com/liubquanti/White-Cobalt'),
                        ),
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

class StorageUsageScreen extends StatefulWidget {
  final String baseDir;

  const StorageUsageScreen({
    Key? key,
    required this.baseDir,
  }) : super(key: key);

  @override
  State<StorageUsageScreen> createState() => _StorageUsageScreenState();
}

class _StorageUsageScreenState extends State<StorageUsageScreen> {
  bool _isLoading = true;
  List<ServiceStorage> _storageData = [];
  int _totalSize = 0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final baseDir = Directory(widget.baseDir);
      
      if (!await baseDir.exists()) {
        setState(() {
          _isLoading = false;
          _storageData = [];
          _totalSize = 0;
        });
        return;
      }

      List<ServiceStorage> data = [];
      int totalSize = 0;

      final List<FileSystemEntity> entities = await baseDir.list().toList();
      final List<Directory> dirs = entities
          .whereType<Directory>()
          .toList();

      for (final dir in dirs) {
        final String serviceName = dir.path.split('/').last;
        final int size = await _calculateDirSize(dir);
        
        if (size > 0) {
          data.add(ServiceStorage(serviceName, size));
          totalSize += size;
        }
                 }

      data.sort((a, b) => b.size.compareTo(a.size));

      setState(() {
        _storageData = data;
        _totalSize = totalSize;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading storage data: $e');
      setState(() {
        _isLoading = false;
        _storageData = [];
        _totalSize = 0;
      });
    }
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int size = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      print('Error calculating size for ${dir.path}: $e');
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> chartColors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFFF5722),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF3F51B5),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Storage Usage'),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorageData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white70,
              ),
            )
          : _totalSize == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No downloads yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When you download files using White Cobalt, they will be stored in:\n\n${widget.baseDir}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Total: ${filesize(_totalSize)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex =
                                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 50,
                                    sections: _storageData.asMap().entries.map((entry) {
                                      final int index = entry.key;
                                      final ServiceStorage data = entry.value;
                                      final bool isTouched = index == _touchedIndex;
                                      final double fontSize = isTouched ? 14.0 : 12.0;
                                      final double radius = isTouched ? 60.0 : 50.0;
                                      final Color color = chartColors[index % chartColors.length];

                                      final double percentage = data.size / _totalSize * 100;
                                      
                                      return PieChartSectionData(
                                        color: color,
                                        value: data.size.toDouble(),
                                        title: '${percentage.toStringAsFixed(1)}%',
                                        radius: radius,
                                        titleStyle: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Service Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: _storageData.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final ServiceStorage data = entry.value;
                            final Color color = chartColors[index % chartColors.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF191919),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                                  width: 1.5,
                                ),
                              ),
                                child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                      data.serviceName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                      filesize(data.size),
                                      style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      ),
                                    ),
                                    ],
                                    ),
                                  ),
                                    ElevatedButton.icon(
                                    onPressed: () => _confirmDeleteDirectory(data.serviceName),
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
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white70),
                                    label: const Text(
                                      'Delete',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    ),
                                  ],
                                ),
                                ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _confirmDeleteDirectory(String serviceName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Delete $serviceName files?',
            style: const TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: const BorderSide(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              width: 2.0,
            ),
          ),
          content: Text(
            'This will permanently delete all downloaded files from $serviceName. Are you sure?',
            style: const TextStyle(fontSize: 14),
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
                Navigator.of(context).pop();
                _deleteDirectory(serviceName);
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

  Future<void> _deleteDirectory(String serviceName) async {
    try {
      final directory = Directory('${widget.baseDir}/$serviceName');
      
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$serviceName files deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _loadStorageData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Directory does not exist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting directory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ServiceStorage {
  final String serviceName;
  final int size;

  ServiceStorage(this.serviceName, this.size);
}