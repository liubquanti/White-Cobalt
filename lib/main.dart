import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  // Important to initialize before the app launches
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize flutter_downloader
  await FlutterDownloader.initialize(
    debug: true // Set to false in release
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
        // Font configuration for the whole app
        fontFamily: 'NotoSansMono',
        // For more precise text style configuration
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w600),
          displayMedium: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'NotoSansMono', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontFamily: 'NotoSansMono'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansMono'),
          bodySmall: TextStyle(fontFamily: 'NotoSansMono'),
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
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _newServerController = TextEditingController();
  String? _baseUrl; // Changed to nullable
  bool _isLoading = false;
  String _status = '';
  Map<String, dynamic>? _serverInfo;
  Map<String, dynamic>? _responseData;
  List<String> _servers = []; // Empty list by default
  bool _noServersConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
    _requestPermissions();
  }

  Future<void> _loadSavedServers() async {
    final prefs = await SharedPreferences.getInstance();
    final servers = prefs.getStringList('servers');
    if (servers != null && servers.isNotEmpty) {
      setState(() {
        _servers = servers;
        _baseUrl = servers.first;
        _noServersConfigured = false;
      });
      _fetchServerInfo();
    } else {
      setState(() {
        _servers = []; // Empty list
        _baseUrl = 'add_new'; // Default to add_new when no servers
        _noServersConfigured = true;
        _status = 'No servers configured. Please add a Cobalt server.';
      });
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('servers', _servers);
  }

  // Modify the _fetchServerInfo() method to verify the server response
  Future<void> _fetchServerInfo() async {
    if (_baseUrl == null) {
      setState(() {
        _serverInfo = null;
        _status = 'No server selected';
        _noServersConfigured = true;
        _isLoading = false; // Make sure to reset loading state
      });
      return;
    }

    setState(() {
      _serverInfo = null;
      _status = 'Checking server...';
      _isLoading = true; // Set loading to true while checking
    });
    
    try {
      final response = await http.get(Uri.parse(_baseUrl!));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Verify if it's a valid Cobalt server by checking for expected data structure
        if (data.containsKey('cobalt') && 
            data['cobalt'].containsKey('version') && 
            data['cobalt'].containsKey('services')) {
          
          setState(() {
            _serverInfo = data;
            _status = 'Connected to Cobalt v${data['cobalt']['version']}';
            _isLoading = false; // Reset loading state
          });
        } else {
          setState(() {
            _status = 'Error: Not a valid Cobalt server';
            _isLoading = false; // Reset loading state
            // Revert to previous server if available
            if (_servers.length > 1 && _baseUrl != _servers.first) {
              _baseUrl = _servers.first;
            }
          });
        }
      } else {
        setState(() {
          _status = 'Server error: ${response.statusCode}';
          _isLoading = false; // Reset loading state
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection error: $e';
        _isLoading = false; // Reset loading state
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
                
                // Show loading state
                setState(() {
                _status = 'Verifying server...';
                _isLoading = true; // Set loading to true
                });
                
                // Try to verify the server before adding
                try {
                final response = await http.get(Uri.parse(newServer));
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  
                  // Check if it's a valid Cobalt server
                  if (data.containsKey('cobalt') && 
                    data['cobalt'].containsKey('version') && 
                    data['cobalt'].containsKey('services')) {
                  
                  setState(() {
                    _servers.add(newServer);
                    _baseUrl = newServer;
                    _serverInfo = data;
                    _noServersConfigured = false;
                    _status = 'Connected to Cobalt v${data['cobalt']['version']}';
                    _isLoading = false; // Reset loading state
                  });
                  _saveServers();
                  } else {
                  setState(() {
                    _status = 'Error: Not a valid Cobalt server';
                    _isLoading = false; // Reset loading state
                  });
                  }
                } else {
                  setState(() {
                  _status = 'Server error: ${response.statusCode}';
                  _isLoading = false; // Reset loading state
                  });
                }
                } catch (e) {
                setState(() {
                  _status = 'Connection error: $e';
                  _isLoading = false; // Reset loading state
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
    // Basic permissions for file downloads on Android
    await Permission.storage.request();
    await Permission.notification.request();
    await Permission.manageExternalStorage.request();
  }

  // First, let's modify the _processUrl() method to properly reset loading state

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
      _status = 'Processing request...';
      _responseData = null;
    });

    try {
      // Validate URL format before sending request
      Uri.parse(url); // This will throw FormatException if the URL is invalid
      
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
          // URL processing - replacing localhost with the actual IP address
          final String downloadUrl = _fixServerUrl(data['url']);
          await _downloadFile(downloadUrl, data['filename']);
        } else if (data['status'] == 'picker') {
          // Picker handling is displayed in the interface
        } else if (data['status'] == 'error') {
          setState(() {
            _status = 'Error: ${data['error']['code']}';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _status = 'Request error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  // Function to fix URLs by replacing localhost with the actual server IP
  String _fixServerUrl(String url) {
    Uri uri = Uri.parse(url);
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      // Use the main server host instead of localhost
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
      // Fixed path to Download directory for Android
      final String downloadsPath = '/storage/emulated/0/Download';
      
      // Creating cobalt_downloads subfolder in Downloads
      final cobaltDownloadsDir = '$downloadsPath/cobalt_downloads';
      final downloadsDir = Directory(cobaltDownloadsDir);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Show URL info for diagnostics
      setState(() {
        _status = 'Starting download: $url\nDirectory: $cobaltDownloadsDir';
      });

      // Starting file download
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: cobaltDownloadsDir,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      setState(() {
        _status = 'Download started: $filename\nTo folder: $cobaltDownloadsDir\n(taskId: $taskId)';
      });
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
      });
    }
  }
  
  Future<void> _downloadPickerItem(String url, String type) async {
    try {
      // Fix URL for picker items as well
      final fixedUrl = _fixServerUrl(url);
      final extension = type == 'photo' ? '.jpg' : type == 'gif' ? '.gif' : '.mp4';
      final filename = 'cobalt_${DateTime.now().millisecondsSinceEpoch}$extension';
      await _downloadFile(fixedUrl, filename);
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
      });
    }
  }

  // Add this method to handle server deletion
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
                  
                  // Handle case when removing the current server
                  if (_baseUrl == server) {
                    // If there are other servers, select the first one
                    if (_servers.isNotEmpty) {
                      _baseUrl = _servers.first;
                      _fetchServerInfo();
                    } else {
                      // If no servers left
                      _baseUrl = null;
                      _serverInfo = null;
                      _noServersConfigured = true;
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

  // In the _CobaltHomePageState class, add a new method to check if a real server is selected:
  bool _isRealServerSelected() {
    return _baseUrl != null && _baseUrl != 'add_new';
  }

  // Fix the UI part in the build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('White Cobalt'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      // Add this to resize the screen when keyboard appears
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(  // Add this wrapper
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
              
              // Always show the dropdown, regardless of server count
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
                // If there are no servers, we'll show 'add_new' as the default value
                value: _servers.isNotEmpty ? _baseUrl : 'add_new',
                items: [
                  // Only map existing servers if there are any
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
                  // Always include the Add New Server option
                  DropdownMenuItem(
                    value: 'add_new',
                    child: Text(
                      'Add New Server',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _servers.isEmpty ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == 'add_new') {
                    _addNewServer();
                    // Set the selected value to indicate we're adding a new server
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
                // If no servers, show a hint text
                hint: _servers.isEmpty ? const Text("No servers configured") : null,
              ),
              
              const SizedBox(height: 10),
              
              // Only show URL field if a REAL server is selected (not "add_new")
              if (_isRealServerSelected())
                TextField(
                  controller: _urlController,
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
                  enabled: false, // Disabled input field when "add_new" is selected
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
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-link "><path d="M9 15l6 -6"></path><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"></path><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463"></path></svg>',
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

              // Only show download button if a REAL server is selected (not "add_new")
              if (_isRealServerSelected()) 
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processUrl,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
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
                    onPressed: null, // Disabled button
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

              Divider(
                color: const Color(0xFF383838),
                thickness: 1.0,
                height: 20,
              ),
              
              // Show server info when available, or "please select server" when add_new is selected
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
              
              // MOVED: Status indicators now appear after the download button
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
            
            // Picker items display
            if (_responseData != null && _responseData!['status'] == 'picker')
              // Use a container with fixed height instead of Expanded 
              Container(
                height: 300, // Adjust this value based on your needs
                padding: const EdgeInsets.only(top: 10.0),
                child: ListView.builder(
                  shrinkWrap: true, // Add this
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
                          onPressed: () => _downloadPickerItem(item['url'], item['type']),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _newServerController.dispose();
    super.dispose();
  }
}
