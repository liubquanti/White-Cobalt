import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:filesize/filesize.dart';

import '../services/storage.dart';

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
  bool _isDeviceStorageLoading = true;
  List<ServiceStorage> _storageData = [];
  int _totalSize = 0;
  int _touchedIndex = -1;
  
  Map<String, dynamic> _deviceStorage = {
    'total': 0,
    'free': 0,
    'used': 0,
    'cobaltPercentage': 0.0
  };

  final List<String> _baseDirs = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Pictures',
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/Music',
  ];

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
      Map<String, int> serviceToSizeMap = {};
      int totalSize = 0;
      
      for (final baseDir in _baseDirs) {
        final cobaltDir = Directory('$baseDir/Cobalt');
        
        if (await cobaltDir.exists()) {
          final List<FileSystemEntity> entities = await cobaltDir.list().toList();
          final List<Directory> dirs = entities
              .whereType<Directory>()
              .toList();
              
          for (final dir in dirs) {
            final String serviceName = dir.path.split('/').last;
            final int size = await _calculateDirSize(dir);
            
            if (size > 0) {
              serviceToSizeMap[serviceName] = (serviceToSizeMap[serviceName] ?? 0) + size;
              totalSize += size;
            }
          }
        }
      }
      
      List<ServiceStorage> data = serviceToSizeMap.entries
          .map((entry) => ServiceStorage(entry.key, entry.value))
          .toList();
      
      data.sort((a, b) => b.size.compareTo(a.size));

      setState(() {
        _storageData = data;
        _totalSize = totalSize;
        _isLoading = false;
      });
      
      _loadDeviceStorageInfo();
    } catch (e) {
      print('Error loading storage data: $e');
      setState(() {
        _isLoading = false;
        _storageData = [];
        _totalSize = 0;
      });
      _loadDeviceStorageInfo();
    }
  }

  Future<void> _loadDeviceStorageInfo() async {
    setState(() {
      _isDeviceStorageLoading = true;
    });
  
    try {
      final stats = await DeviceStorageInfo.getStorageStats();
    
      setState(() {
        _deviceStorage = stats;
        if (_totalSize > 0) {
          _deviceStorage['cobaltPercentage'] = _totalSize / stats['total'] * 100;
        } else {
          _deviceStorage['cobaltPercentage'] = 0.0;
        }
        _isDeviceStorageLoading = false;
      });
    
      print('Device storage: ${filesize(stats['total'])} total, ${filesize(stats['free'])} free');
      print('Cobalt is using: ${filesize(_totalSize)} (${_deviceStorage['cobaltPercentage'].toStringAsFixed(2)}%)');
    } catch (e) {
      print('Error loading device storage info: $e');
      setState(() {
        _isDeviceStorageLoading = false;
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                year2023: false,
                color: Colors.white,
                backgroundColor: Colors.grey,
              ),
            )
          : _totalSize == 0
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-files-off"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 3v4a1 1 0 0 0 1 1h4" /><path d="M17 17h-6a2 2 0 0 1 -2 -2v-6m0 -4a2 2 0 0 1 2 -2h4l5 5v7c0 .294 -.063 .572 -.177 .823" /><path d="M16 17v2a2 2 0 0 1 -2 2h-7a2 2 0 0 1 -2 -2v-10a2 2 0 0 1 2 -2" /><path d="M3 3l18 18" /></svg>',
                          width: 64,
                          height: 64,
                          colorFilter: const ColorFilter.mode(Colors.white30, BlendMode.srcIn),
                        ),
                        const Text(
                          'No Downloads Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When you download files using White Cobalt, here will be storage usage stats.',
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
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Total: ${filesize(_totalSize)} / ${filesize(_deviceStorage['total'])}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
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
                                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 60,
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
                                  _isDeviceStorageLoading
                                    ? const SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(
                                          year2023: false,
                                          color: Colors.white,
                                          backgroundColor: Colors.grey,
                                        ),
                                      )
                                    : SizedBox(
                                        height: 60,
                                        width: 60,
                                          child: PieChart(
                                          PieChartData(
                                            pieTouchData: PieTouchData(enabled: false),
                                            borderData: FlBorderData(show: false),
                                            centerSpaceRadius: 40,
                                            sections: [
                                            PieChartSectionData(
                                              color: const Color(0xFFFFFFFF),
                                              value: _totalSize.toDouble(),
                                              title: '',
                                              radius: 10,
                                              showTitle: false,
                                            ),
                                            PieChartSectionData(
                                              color: const Color(0xFF949494),
                                              value: _deviceStorage['used'] - _totalSize.toDouble(),
                                              title: '',
                                              radius: 10,
                                              showTitle: false,
                                            ),
                                            PieChartSectionData(
                                              color: const Color(0xFF333333),
                                              value: _deviceStorage['free'].toDouble(),
                                              title: '',
                                              radius: 10,
                                              showTitle: false,
                                            ),
                                            ],
                                          ),
                                          ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                        SvgPicture.string(
                                          '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-database"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" /><path d="M4 6v6a8 3 0 0 0 16 0v-6" /><path d="M4 12v6a8 3 0 0 0 16 0v-6" /></svg>',
                                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                        ),
                                        Text(
                                          '${_deviceStorage["cobaltPercentage"].toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          ),
                                        ),
                                        ],
                                      )
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.08),
                              width: 1.5,
                            ),
                          ),
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                              Row(
                                children: [
                                Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                color: Color(0xFFFFFFFF),
                                shape: BoxShape.circle,
                                ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                'Cobalt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                ),
                                ],
                              ),
                              Row(
                                children: [
                                Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                color: Color(0xFF949494),
                                shape: BoxShape.circle,
                                ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                'Other',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                ),
                                ],
                              ),
                              Row(
                                children: [
                                Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                color: Color(0xFF333333),
                                shape: BoxShape.circle,
                                ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                ),
                                ],
                              ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: _storageData.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final ServiceStorage data = entry.value;
                            final Color color = chartColors[index % chartColors.length];

                            return Container(
                              margin: EdgeInsets.only(bottom: index == _storageData.length - 1 ? 0 : 10),
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
                                    icon: SvgPicture.string(
                                      '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-trash"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 7l16 0" /><path d="M10 11l0 6" /><path d="M14 11l0 6" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg>',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
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
                        const SizedBox(height: 16),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
          'Are you sure you want to delete all downloaded files from $serviceName?',
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
      bool hasDeleted = false;
      
      for (final baseDir in _baseDirs) {
        final directory = Directory('$baseDir/Cobalt/$serviceName');
        
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          hasDeleted = true;
          print('Deleted $serviceName from $baseDir/Cobalt');
        }
      }
      
      if (hasDeleted) {
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
              content: Text('No directories found for this service'),
              backgroundColor: Colors.orange,
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