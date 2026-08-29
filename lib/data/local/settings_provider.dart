import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_config.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppColorTheme _colorTheme = AppColorTheme.original;
  Locale _locale = const Locale('ar');
  String _backendBaseUrl = ApiConfig.baseUrl;

  ThemeMode get themeMode => _themeMode;
  AppColorTheme get colorTheme => _colorTheme;
  Locale get locale => _locale;
  String get backendBaseUrl => _backendBaseUrl;
  bool get hasCustomBackendUrl => ApiConfig.hasSavedOverride;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final savedColorTheme = prefs.getString('colorTheme');
    final langCode = prefs.getString('languageCode') ?? 'ar';

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _colorTheme = AppColorTheme.values.firstWhere(
      (theme) => theme.name == savedColorTheme,
      orElse: () => AppColorTheme.original,
    );
    _locale = Locale(langCode);
    _backendBaseUrl = ApiConfig.baseUrl;
    notifyListeners();
  }

  Future<void> setBackendBaseUrl(String value) async {
    await ApiConfig.setBaseUrl(value);
    _backendBaseUrl = ApiConfig.baseUrl;
    notifyListeners();
  }

  Future<void> resetBackendBaseUrl() async {
    await ApiConfig.resetBaseUrl();
    _backendBaseUrl = ApiConfig.baseUrl;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    if (_colorTheme == theme) return;
    _colorTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colorTheme', theme.name);
  }

  Future<void> setLocale(String langCode) async {
    _locale = Locale(langCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
  }
}
