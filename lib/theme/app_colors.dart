import 'package:flutter/material.dart';

/// Single source of truth for every colour used by the app.
abstract final class AppColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF191919);
  static const surfaceRaised = Color(0xFF2A2A2A);
  static const selected = Color(0xFF333333);
  static const outline = Color(0xFF383838);
  static const focus = Color(0xFFB1B1B1);
  static const switchTrack = Color(0xFF8A8A8A);
  static const storageOther = Color(0xFF949494);

  /// White at 8% — default card/button border.
  static const border = Color(0x14FFFFFF);

  /// White at 5% — subtle border for passive containers.
  static const borderSubtle = Color(0x0CFFFFFF);

  static const text = Color(0xFFE1E1E1);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textMuted = Colors.white54;
  static const textDisabled = Colors.white38;

  static const success = Colors.green;
  static const error = Colors.red;
  static const warning = Colors.orange;
  static const caution = Colors.amber;
  static const destructive = Colors.redAccent;

  /// Palette for the per-service storage chart.
  static const chart = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];
}

abstract final class AppRadii {
  static const double card = 11;
  static const double small = 8;
  static const double pill = 12;

  static final cardBorder = BorderRadius.circular(card);
  static final smallBorder = BorderRadius.circular(small);
}

abstract final class AppSpacing {
  /// Gap between sibling cards.
  static const double gap = 10;

  /// Gap before a new section header.
  static const double section = 15;

  /// Horizontal page padding.
  static const double page = 16;
}

abstract final class AppTextStyles {
  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const tileTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const caption = TextStyle(fontSize: 12, color: AppColors.textSecondary);
  static const small = TextStyle(fontSize: 12);
  static const badge = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);
}
