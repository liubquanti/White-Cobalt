import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  final bool disableMetadata;
  final ValueChanged<bool> onChanged;
  final bool shareCopyToClipboard;
  final ValueChanged<bool> onShareCopyChanged;

  const AdvancedSettingsScreen({
    Key? key,
    required this.disableMetadata,
    required this.onChanged,
    this.shareCopyToClipboard = false,
    required this.onShareCopyChanged,
  }) : super(key: key);

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late bool _disableMetadata;
  late bool _shareCopyToClipboard;

  @override
  void initState() {
    super.initState();
    _disableMetadata = widget.disableMetadata;
    _shareCopyToClipboard = widget.shareCopyToClipboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Advanced Settings'),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-file-download "><path d="M14 3v4a1 1 0 0 0 1 1h4"></path><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"></path><path d="M12 17v-6"></path><path d="M9.5 14.5l2.5 2.5l2.5 -2.5"></path></svg>',
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
                      widget.onChanged(value);
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
                            '<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-clipboard-plus"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z" /><path d="M10 14h4" /><path d="M12 12v4" /></svg>',
                            colorFilter: ColorFilter.mode(
                              _shareCopyToClipboard ? Colors.white : Colors.white38,
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
                                'Copy Share Links',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _shareCopyToClipboard ? Colors.white : Colors.white54,
                                ),
                              ),
                              Text(
                                'Copy to clipboard instead of opening share menu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _shareCopyToClipboard ? Colors.white70 : Colors.white38,
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
                    value: _shareCopyToClipboard,
                    onChanged: (value) {
                      setState(() {
                        _shareCopyToClipboard = value;
                      });
                      widget.onShareCopyChanged(value);
                    },
                    activeColor: const Color(0xFFFFFFFF),
                    activeTrackColor: const Color(0xFF8a8a8a),
                    inactiveThumbColor: const Color(0xFFFFFFFF),
                    inactiveTrackColor: const Color(0xFF383838),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}