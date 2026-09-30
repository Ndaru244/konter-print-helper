import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:cetak_struk/theme/app_colors.dart";

abstract final class AppTheme {
  static const double _radiusMd = 12;
  static const double _radiusLg = 16;

  static ThemeData light({Color seed = AppColors.primary500}) =>
      _build(dark: false, seed: seed);

  static ThemeData dark({Color seed = AppColors.primary500}) =>
      _build(dark: true, seed: seed);

  static ThemeData _build({required bool dark, required Color seed}) {
    final title = dark ? AppColors.slate50 : AppColors.slate900;
    final body = dark ? AppColors.slate100 : AppColors.slate900;
    final secondary = dark ? AppColors.slate300 : AppColors.slate600;
    final caption = dark ? AppColors.slate400 : AppColors.slate500;
    final field = dark ? AppColors.slate300 : AppColors.slate700;
    final surface = dark ? AppColors.slate800 : Colors.white;
    final outline = dark ? AppColors.slate700 : AppColors.slate200;
    final scaffold = dark ? AppColors.slate900 : AppColors.slate50;
    final icon = dark ? AppColors.slate300 : AppColors.slate700;
    final inputFill = dark ? AppColors.slate900 : AppColors.slate50;

    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    final colorScheme = generated.copyWith(
      primary: dark ? generated.primary : seed,
      onPrimary: dark ? generated.onPrimary : Colors.white,
      surface: surface,
      onSurface: title,
      onSurfaceVariant: secondary,
      outline: outline,
      error: AppColors.dangerIcon,
      onError: Colors.white,
    );
    final accent = colorScheme.primary;
    final navSelected = dark
        ? AppColors.accentOnDark(seed)
        : colorScheme.primary;

    final titleLarge = TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
      color: title,
    );
    final textTheme = TextTheme(
      titleLarge: titleLarge,
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: title,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: body,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: caption,
      ),
      labelLarge: const TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: caption,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: caption,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusMd),
    );
    final fieldLabel = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: field,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: icon, size: 24),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        foregroundColor: title,
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: title, size: 24),
        actionsIconTheme: IconThemeData(color: title, size: 24),
        // Transparent AppBar estimates as dark (ARGB 0) and would force light
        // icons; set overlay explicitly so light mode keeps dark icons.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          iconSize: 24,
          foregroundColor: title,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? navSelected : secondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? navSelected : secondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: accent,
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
          backgroundColor: accent,
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
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: dark ? AppColors.slate700 : AppColors.slate300,
          ),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: accent,
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
        fillColor: inputFill,
        isDense: false,
        labelStyle: fieldLabel,
        floatingLabelStyle: fieldLabel.copyWith(color: accent),
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
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: accent, width: 2),
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
