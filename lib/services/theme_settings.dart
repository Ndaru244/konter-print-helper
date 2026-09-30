import "package:cetak_struk/theme/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

enum AppThemeChoice { system, light, dark }

enum AppPrimaryPreset { biru, ungu, hijau, custom }

class ThemeSettings extends ChangeNotifier with WidgetsBindingObserver {
  static const prefsKey = "theme_mode";
  static const primaryPresetKey = "primary_preset";
  static const primaryCustomKey = "primary_custom";

  static const biru = AppColors.primaryBiru;
  static const ungu = AppColors.primary500;
  static const hijau = AppColors.primaryHijau;

  AppThemeChoice _choice = AppThemeChoice.system;
  AppPrimaryPreset _primaryPreset = AppPrimaryPreset.ungu;
  Color _customPrimary = ungu;

  AppThemeChoice get choice => _choice;

  AppPrimaryPreset get primaryPreset => _primaryPreset;

  Color get customPrimary => _customPrimary;

  Color get seedColor => switch (_primaryPreset) {
    AppPrimaryPreset.biru => biru,
    AppPrimaryPreset.hijau => hijau,
    AppPrimaryPreset.custom => _customPrimary,
    AppPrimaryPreset.ungu => ungu,
  };

  ThemeMode get themeMode => switch (_choice) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.light => ThemeMode.light,
    AppThemeChoice.dark => ThemeMode.dark,
  };

  ThemeSettings() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _choice = switch (prefs.getString(prefsKey)) {
      "light" => AppThemeChoice.light,
      "dark" => AppThemeChoice.dark,
      _ => AppThemeChoice.system,
    };
    _primaryPreset = switch (prefs.getString(primaryPresetKey)) {
      "biru" => AppPrimaryPreset.biru,
      "hijau" => AppPrimaryPreset.hijau,
      "custom" => AppPrimaryPreset.custom,
      _ => AppPrimaryPreset.ungu,
    };
    final custom = prefs.getInt(primaryCustomKey);
    if (custom != null) _customPrimary = Color(custom).withValues(alpha: 1);
    _applyOverlay();
    notifyListeners();
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    if (_choice == choice) return;
    _choice = choice;
    _applyOverlay();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, choice.name);
  }

  Future<void> setPrimaryPreset(AppPrimaryPreset preset) async {
    if (_primaryPreset == preset) return;
    _primaryPreset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(primaryPresetKey, preset.name);
  }

  Future<void> setCustomPrimary(Color color) async {
    _customPrimary = color.withValues(alpha: 1);
    _primaryPreset = AppPrimaryPreset.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(primaryPresetKey, AppPrimaryPreset.custom.name);
    await prefs.setInt(primaryCustomKey, _customPrimary.toARGB32());
  }

  @override
  void didChangePlatformBrightness() {
    if (_choice == AppThemeChoice.system) _applyOverlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _applyOverlay() {
    final brightness = switch (_choice) {
      AppThemeChoice.light => Brightness.light,
      AppThemeChoice.dark => Brightness.dark,
      AppThemeChoice.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    final onDark = brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: onDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: onDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
