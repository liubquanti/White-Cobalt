import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'svg_icon.dart';

/// The rounded, bordered dark container that nearly every block in the app
/// is built from. Optionally tappable (ripple is clipped to the shape).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.gap),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  /// Clip children (e.g. images) to the rounded shape.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardBorder,
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      clipBehavior: (onTap != null || clip) ? Clip.antiAlias : Clip.none,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Small rounded label ("KEY", "Official", status badges, scores).
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = Colors.white,
    this.textColor = Colors.black,
    this.width,
  });

  final String text;
  final Color color;
  final Color textColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: width == null ? null : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(text, style: AppTextStyles.badge.copyWith(color: textColor)),
    );
  }
}

/// Card with a coloured status icon, bold title and a caption underneath.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.lines = const [],
  });

  final String icon;
  final Color iconColor;
  final String title;
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SurfaceCard(
        borderColor: AppColors.borderSubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgIcon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
              ],
            ),
            if (lines.isNotEmpty) const SizedBox(height: 4),
            ...lines,
          ],
        ),
      ),
    );
  }
}

/// Small square bordered button with an icon and optional label — used for
/// "Add server", website, GitHub, social links, etc.
class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
    this.labelStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  });

  final String icon;
  final VoidCallback? onTap;
  final String? label;
  final String? tooltip;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.smallBorder,
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgIcon(icon, size: 24),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!, style: labelStyle),
              ],
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip, child: button);
    return button;
  }
}

/// Section title + its children, separated by the standard gaps.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.children, this.first = false});

  final String title;
  final List<Widget> children;

  /// The first section on a page has no top gap.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: AppSpacing.section),
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.gap),
        ...separated(children),
      ],
    );
  }
}

/// Inserts a standard vertical gap between [children].
List<Widget> separated(List<Widget> children, {double gap = AppSpacing.gap}) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      children[i],
    ],
  ];
}
