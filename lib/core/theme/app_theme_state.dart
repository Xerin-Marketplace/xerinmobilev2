part of 'app_theme_cubit.dart';

class AppThemeState extends Equatable {
  final ThemeMode themeMode;

  const AppThemeState(this.themeMode);

  bool get isLight => themeMode == ThemeMode.light;
  bool get isDark => themeMode == ThemeMode.dark;
  bool get isSystem => themeMode == ThemeMode.system;

  IconData get icon {
    switch (themeMode) {
      case ThemeMode.light:
        return Uicons.sun;
      case ThemeMode.dark:
        return Uicons.darkMode;
      case ThemeMode.system:
        return Uicons.brightness;
    }
  }

  String get label {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  List<Object?> get props => [themeMode];
}
