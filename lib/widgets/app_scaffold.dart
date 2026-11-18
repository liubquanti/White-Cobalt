import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'svg_icon.dart';

/// Standard page shell: black background, centred title and a chevron back
/// button. Replaces the identical AppBar block that every screen duplicated.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Overrides the default back button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading ?? const AppBackButton(),
        actions: actions,
      ),
      body: body,
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const SvgIcon(AppIcons.chevronLeft),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.maybePop(context),
    );
  }
}

/// Scrollable page body with the standard horizontal padding and room for the
/// system navigation bar at the bottom.
class PageScrollView extends StatelessWidget {
  const PageScrollView({
    super.key,
    required this.children,
    this.top = 0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double top;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        top,
        AppSpacing.page,
        MediaQuery.paddingOf(context).bottom + AppSpacing.page,
      ),
      child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
    );
  }
}
