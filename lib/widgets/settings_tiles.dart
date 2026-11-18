import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'cards.dart';
import 'svg_icon.dart';

/// Icon + title + optional subtitle. Dims itself when [active] is false.
class _TileLabel extends StatelessWidget {
  const _TileLabel({required this.icon, required this.title, this.subtitle, this.active = true});

  final String icon;
  final String title;
  final String? subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgIcon(icon, color: active ? AppColors.textPrimary : AppColors.textDisabled),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.tileTitle.copyWith(
                  color: active ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.textSecondary : AppColors.textDisabled,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings row with a switch. The whole row is tappable.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(child: _TileLabel(icon: icon, title: title, subtitle: subtitle, active: value)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Settings row that opens another page.
class NavTile extends StatelessWidget {
  const NavTile({super.key, required this.icon, required this.title, required this.onTap});

  final String icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _TileLabel(icon: icon, title: title)),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Settings row with a compact dropdown on the right.
class DropdownTile extends StatelessWidget {
  const DropdownTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _TileLabel(icon: icon, title: title, subtitle: subtitle)),
          const SizedBox(width: 5),
          Container(
            width: 70,
            height: 40,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: AppRadii.smallBorder,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.contains(value) ? value : options.first,
                borderRadius: AppRadii.cardBorder,
                alignment: AlignmentDirectional.centerEnd,
                dropdownColor: AppColors.surface,
                icon: const SvgIcon(AppIcons.selector, color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'NotoSansMono'),
                items: [
                  for (final option in options)
                    DropdownMenuItem(
                      value: option,
                      alignment: AlignmentDirectional.center,
                      child: Text(option),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
