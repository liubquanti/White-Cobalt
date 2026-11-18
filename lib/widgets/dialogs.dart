import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../generated/codegen_loader_keys.g.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'svg_icon.dart';

/// The app's dialog chrome (black, rounded, thin border, full-width).
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.content, required this.actions});

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardBorder,
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Padding(padding: const EdgeInsets.only(bottom: 5), child: content),
      ),
      actions: actions,
    );
  }
}

/// Dialog action button; red text when [destructive].
class DialogButton extends StatelessWidget {
  const DialogButton({super.key, required this.label, required this.onPressed, this.destructive = false});

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.destructive) : null,
      child: Text(label),
    );
  }
}

/// Yes/no confirmation. Resolves to `true` only when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(message, style: const TextStyle(fontSize: 14)),
      ),
      actions: [
        DialogButton(
          label: LocaleKeys.Cancel.tr(),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogButton(
          label: confirmLabel,
          destructive: destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Result of [showAddServerDialog].
class AddServerInput {
  const AddServerInput({required this.url, this.apiKey});

  final String url;
  final String? apiKey;
}

/// Dialog asking for an (optional) API key, and optionally a server address.
///
/// When [fixedUrl] is given only the API key is requested and [header] is
/// shown above the field; otherwise the user types the server address too.
Future<AddServerInput?> showAddServerDialog(
  BuildContext context, {
  required String title,
  String? fixedUrl,
  Widget? header,
}) {
  return showDialog<AddServerInput>(
    context: context,
    builder: (context) => _AddServerDialog(title: title, fixedUrl: fixedUrl, header: header),
  );
}

class _AddServerDialog extends StatefulWidget {
  const _AddServerDialog({required this.title, this.fixedUrl, this.header});

  final String title;
  final String? fixedUrl;
  final Widget? header;

  @override
  State<_AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<_AddServerDialog> {
  final _url = TextEditingController();
  final _apiKey = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _submit() {
    final url = widget.fixedUrl ?? _url.text.trim();
    final key = _apiKey.text.trim();
    Navigator.of(context).pop(
      url.isEmpty ? null : AddServerInput(url: url, apiKey: key.isEmpty ? null : key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.header != null) ...[widget.header!, const SizedBox(height: 16)],
          if (widget.fixedUrl == null) ...[
            TextField(
              controller: _url,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterServerAddress.tr(),
                prefixIcon: const InputIcon(AppIcons.server),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _apiKey,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: LocaleKeys.APIKeyOptional.tr(),
              prefixIcon: const InputIcon(AppIcons.key),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        DialogButton(label: LocaleKeys.Cancel.tr(), onPressed: () => Navigator.of(context).pop()),
        DialogButton(label: LocaleKeys.Add.tr(), onPressed: _submit),
      ],
    );
  }
}
