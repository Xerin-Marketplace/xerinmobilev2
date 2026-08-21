import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/uicons.dart';

part 'app_theme_state.dart';

class AppThemeCubit extends Cubit<AppThemeState> {
  final SharedPreferences _prefs;

  AppThemeCubit(this._prefs) : super(const AppThemeState(ThemeMode.system)) {
    _loadTheme();
  }

  static const String _themeKey = 'app_theme_mode';

  void _loadTheme() {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      emit(AppThemeState(_themeModeFromString(savedTheme)));
    }
  }

  void setThemeMode(ThemeMode mode) {
    _prefs.setString(_themeKey, _themeModeToString(mode));
    emit(AppThemeState(mode));
  }

  void toggleTheme() {
    final currentMode = state.themeMode;
    ThemeMode newMode;

    switch (currentMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        // Default to light when toggling from system
        newMode = ThemeMode.light;
        break;
    }

    setThemeMode(newMode);
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
