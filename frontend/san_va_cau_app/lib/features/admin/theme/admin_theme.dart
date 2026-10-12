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
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const info = AppColors.info;

  static const pagePadding = 20.0;
  static const cardRadius = 18.0;
  static const compactRadius = 14.0;
  static const touchTarget = 48.0;
}
