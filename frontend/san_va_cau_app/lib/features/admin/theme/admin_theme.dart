import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

abstract final class AdminTheme {
  static const graphite = Color(0xFF17191D);
  static const graphiteSurface = Color(0xFF202329);
  static const canvas = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF17191D);
  static const textSecondary = Color(0xFF667085);
  static const border = Color(0xFFE6E8EC);
  static const navigationMuted = Color(0xFFB7BBC2);

  static const primary = AppColors.primary;
  static const primaryText = AppColors.primaryDark;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const info = AppColors.info;
  static const successText = Color(0xFF137333);
  static const warningText = Color(0xFF9A3412);

  static const pagePadding = 20.0;
  static const cardRadius = 18.0;
  static const compactRadius = 14.0;
  static const touchTarget = 48.0;

  static ThemeData data(ThemeData base) => base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: canvas,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: graphite,
      foregroundColor: Colors.white,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compactRadius),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compactRadius),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compactRadius),
        borderSide: const BorderSide(color: primary),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(touchTarget, 56),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compactRadius),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(touchTarget, 56),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compactRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(touchTarget, touchTarget),
        foregroundColor: primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(touchTarget, 48),
        foregroundColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compactRadius),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: base.textTheme.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: base.textTheme.labelLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: surface,
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: border),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(touchTarget, touchTarget),
      ),
    ),
  );
}
