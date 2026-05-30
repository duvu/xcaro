# Design System Spec

## Overview

Establish a centralised design system for XCaro that all screens and widgets consume. No screen-specific logic — this is tokens only.

## Requirements

### DS-1: AppColors constants file
- `AppColors` must define all colour constants as `static const Color` values.
- Must include: `primary`, `secondary` (gold), `boardBackground`, `stoneBlack`, `stoneWhite`, `success`, `warning`, `error`, and semantic surface colours.
- Must NOT contain any widget code or Flutter framework imports beyond `dart:ui` / `material.dart` colour types.

### DS-2: AppSpacing token file
- `AppSpacing` must define `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32) as `static const double`.
- Must define `radius` (12), `radiusLg` (20), `radiusFull` (100) for border radii.

### DS-3: AppTextStyles file
- `AppTextStyles` must expose a static `textTheme()` returning a `TextTheme` using `GoogleFonts.nunitoTextTheme()`.
- Must define named static `TextStyle` getters for at least: `displayLarge`, `headlineMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelSmall`.

### DS-4: AppTheme file
- `AppTheme.light()` returns a complete `ThemeData` with `useMaterial3: true`, hand-crafted `ColorScheme` from `AppColors` light values, `AppBarTheme` (navy background, white foreground, elevation 0), `ElevatedButtonThemeData`, `InputDecorationTheme` (filled, rounded), `CardTheme`, and `TextTheme` from `AppTextStyles`.
- `AppTheme.dark()` returns a mirrored dark `ThemeData`.
- No hardcoded `Colors.*` references in `app_theme.dart` — all colours come from `AppColors`.

### DS-5: pubspec.yaml dependency
- `google_fonts: ^6.0.0` added to dependencies in `client/pubspec.yaml`.

### DS-6: main.dart updated
- `main.dart` `MaterialApp.theme` set to `AppTheme.light()`.
- `MaterialApp.darkTheme` set to `AppTheme.dark()`.
- Remove `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` references.

## Acceptance Criteria

- `flutter analyze` reports 0 issues after applying this capability.
- `AppColors`, `AppSpacing`, `AppTextStyles`, `AppTheme` are importable from any screen file.
- All four light+dark theme colours are visually distinct and pass WCAG AA contrast on white/dark surfaces.
