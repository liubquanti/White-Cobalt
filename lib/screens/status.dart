import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ServiceStatusScreen extends StatefulWidget {
  const ServiceStatusScreen({Key? key}) : super(key: key);

  @override
  State<ServiceStatusScreen> createState() => _ServiceStatusScreenState();
}

class _ServiceStatusScreenState extends State<ServiceStatusScreen> {
  Map<String, dynamic>? _statusData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatusData();
  }

  Future<void> _loadStatusData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://stats.uptimerobot.com/api/getMonitorList/NowpAIVNnk'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _statusData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load status data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String statusClass) {
    switch (statusClass) {
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statusClass) {
    switch (statusClass) {
      case 'success':
        return 'Online';
      case 'danger':
        return 'Offline';
      case 'warning':
        return 'Warning';
      default:
        return 'Unknown';
    }
  }

  Color _getDayColor(String color) {
    switch (color) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.amber;
      case 'blue':
        return Colors.blue;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Service Status'),
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
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                      'An error occurred while loading service statuses. Please try again or check the information in your browser.',
                      textAlign: TextAlign.center,
                      ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                        onPressed: _loadStatusData,
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
                        child: const Text('Retry'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse('https://stats.uptimerobot.com/NowpAIVNnk');
                          if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
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
                        child: const Text('In Browser'),
                        ),
                      ],
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_statusData != null && _statusData!['data'] != null)
                        ..._statusData!['data'].map<Widget>((monitor) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: monitor == _statusData!['data'].last ? 0 : 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF191919),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          monitor['name'] ?? 'Unknown',
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
                                          color: _getStatusColor(monitor['statusClass']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(monitor['statusClass']),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  if (monitor['dailyRatios'] != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Last 90 days',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 10,
                                          child: Row(
                                            children: monitor['dailyRatios']
                                                .map<Widget>((day) {
                                              return Expanded(
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                                  decoration: BoxDecoration(
                                                    color: _getDayColor(day['color']),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildUptimeChip(
                                        'Last 24h',
                                        monitor['ratio']?['ratio'] ?? '0',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildUptimeChip(
                                        'Last 7d',
                                        monitor['30dRatio']?['ratio'] ?? '0',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildUptimeChip(
                                        'Last 30d',
                                        monitor['90dRatio']?['ratio'] ?? '0',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUptimeChip(String label, String value) {
    final uptimeValue = double.tryParse(value) ?? 0;
    Color color;
    if (uptimeValue >= 99) {
      color = Colors.green;
    } else if (uptimeValue >= 95) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
        color: const Color(0xFF191919),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${uptimeValue.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
