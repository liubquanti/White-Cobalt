import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logger.dart';

/// Lets the ink ripple play before navigating — the delay that used to be
/// copy-pasted into every onTap handler.
const rippleDelay = Duration(milliseconds: 250);

Future<T?> pushPage<T>(BuildContext context, Widget page) async {
  await Future<void>.delayed(rippleDelay);
  if (!context.mounted) return null;
  return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
}

/// Opens [url] in an external app, but only for http(s) links.
///
/// Several URLs come from third-party data (instance lists, changelog
/// markdown, the remote banner). Allowing arbitrary schemes would let such
/// data fire `intent:`, `file:` or other deep links on the device.
Future<bool> openExternalUrl(String? url) async {
  final uri = url == null ? null : Uri.tryParse(url.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
    logDebug('Refusing to open non-http(s) URL: $url');
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    logDebug('Could not open $url: $e');
    return false;
  }
}
