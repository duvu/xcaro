import 'package:flutter/material.dart';

/// Brand colour palette for PlayVerse.
/// Use these constants instead of raw hex literals throughout the app.
abstract class AppColors {
  // Primary brand colours
  static const Color primary = Color(0xFF1A2035); // navy
  static const Color primaryDark = Color(0xFF2D3A5C);
  static const Color secondary = Color(0xFFD4AF37); // gold
  static const Color secondaryDark = Color(0xFFE8C84A);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainer = Color(0xFFF5F5F5);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);

  // On-colours
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color error = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color success = Color(0xFF388E3C);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFFFA726);

  // Game-specific
  static const Color boardBackground = Color(0xFFDCB97A);
  static const Color boardBackgroundDark = Color(0xFFC8A060);
  static const Color stoneBlack = Color(0xFF1A1A1A);
  static const Color stoneBlackDark = Color(0xFF0D0D0D);
  static const Color stoneWhite = Color(0xFFF0F0F0);
  static const Color stoneWhiteDark = Color(0xFFE8E8E8);
  static const Color winLine = Color(0xFFD4AF37); // same as secondary
}
