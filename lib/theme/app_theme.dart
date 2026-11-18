import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// App-wide theme. Component styles that used to be repeated inline on every
/// screen (inputs, switches, buttons, dividers, app bars) live here, so
/// widgets only override what is genuinely different.
abstract final class AppTheme {
  static const overlayStyle = SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static final ButtonStyle filledButtonStyle = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
    backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
    foregroundColor: const WidgetStatePropertyAll(AppColors.text),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: AppRadii.cardBorder,
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: AppRadii.cardBorder,
        borderSide: BorderSide(width: 1.5, color: color),
      );

  static final ThemeData dark = _build();

  static ThemeData _build() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'NotoSansMono',
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        centerTitle: true,
        systemOverlayStyle: overlayStyle,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: _inputBorder(AppColors.outline),
        enabledBorder: _inputBorder(AppColors.outline),
        disabledBorder: _inputBorder(AppColors.outline),
        focusedBorder: _inputBorder(AppColors.focus),
        contentPadding: const EdgeInsets.all(5),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.text),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.switchTrack : AppColors.outline,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledButtonStyle),
      textButtonTheme: TextButtonThemeData(
        style: filledButtonStyle.copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppRadii.cardBorder,
              side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
