import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_colors.dart';
import 'package:nuvora/core/theme/app_radius.dart';
import 'package:nuvora/core/theme/app_spacing.dart';
import 'package:nuvora/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return _buildTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      surfaceColor: AppColors.lightSurface,
      onSurfaceColor: AppColors.lightOnSurface,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return _buildTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      surfaceColor: AppColors.darkSurface,
      onSurfaceColor: AppColors.darkOnSurface,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color surfaceColor,
    required Color onSurfaceColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: onSurfaceColor,
        titleTextStyle: AppTypography.h2.copyWith(color: onSurfaceColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
      ),
    );
  }
}

ThemeData buildAppTheme() => AppTheme.light();

ThemeData buildDarkAppTheme() => AppTheme.dark();
