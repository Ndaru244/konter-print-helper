import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

abstract final class AppTheme {
  static const double _radiusMd = 12;
  static const double _radiusLg = 16;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF8F00BF),
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          onSurface: AppColors.slate900,
          onSurfaceVariant: AppColors.slate600,
          outline: AppColors.slate200,
          error: AppColors.dangerIcon,
          onError: Colors.white,
          onPrimary: Colors.white,
        );

    const titleLarge = TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
      color: AppColors.slate900,
    );

    const textTheme = TextTheme(
      titleLarge: titleLarge,
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: AppColors.slate900,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.slate900,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.slate600,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.slate500,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.slate500,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.slate500,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusMd),
    );
    const fieldLabel = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: AppColors.slate700,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate50,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.slate700, size: 24),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        foregroundColor: AppColors.slate900,
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: AppColors.slate900, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.slate900, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          side: const BorderSide(color: AppColors.slate200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: AppColors.slate300),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        isDense: false,
        labelStyle: fieldLabel,
        floatingLabelStyle: fieldLabel.copyWith(color: colorScheme.primary),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.slate400),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.dangerText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: AppColors.dangerIcon),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: AppColors.dangerIcon, width: 2),
        ),
      ),
    );
  }
}
