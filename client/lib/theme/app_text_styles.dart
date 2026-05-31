import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography definitions for PlayVerse.
/// Provides a complete TextTheme and named convenience getters.
abstract class AppTextStyles {
  /// Returns a TextTheme based on Nunito (Google Fonts).
  /// Falls back to the system default if fonts cannot be loaded.
  static TextTheme textTheme([Color? color]) {
    return GoogleFonts.nunitoTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color),
        headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color),
        titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color),
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: color),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: color),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color),
      ),
    );
  }

  // Named convenience styles
  static TextStyle get displayLarge =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold);

  static TextStyle get headlineMedium =>
      GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w600);

  static TextStyle get titleLarge =>
      GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.normal);

  static TextStyle get bodyMedium =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.normal);

  static TextStyle get labelLarge =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get labelSmall =>
      GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500);
}
