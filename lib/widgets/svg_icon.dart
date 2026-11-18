import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Renders one of the [AppIcons] SVG strings tinted with [color].
class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.svg, {
    super.key,
    this.size = 22,
    this.color = AppColors.textPrimary,
  });

  final String svg;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Fixed-size icon slot used as `prefixIcon` inside text fields/dropdowns.
class InputIcon extends StatelessWidget {
  const InputIcon(this.svg, {super.key, this.color = AppColors.textSecondary, this.size = 22});

  final String svg;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(child: SvgIcon(svg, size: size, color: color)),
    );
  }
}
