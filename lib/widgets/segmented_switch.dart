import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pill-style segmented control (download mode, instance source tabs).
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.height = 32,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;

  /// Null disables the whole control.
  final ValueChanged<T>? onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    final radius = BorderRadius.circular(9);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: enabled ? AppColors.border : const Color(0x0AFFFFFF), width: 1.5),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: Material(
                color: enabled && value == selected ? AppColors.selected : Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: enabled ? () => onSelected!(value) : null,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        labelOf(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: enabled && value == selected ? FontWeight.bold : FontWeight.normal,
                          color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
