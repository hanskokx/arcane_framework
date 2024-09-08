import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

class ArcaneReactiveTheme extends ArcaneService {
  static final ArcaneReactiveTheme _instance = ArcaneReactiveTheme._internal();

  static ArcaneReactiveTheme get I => _instance;

  ArcaneReactiveTheme._internal();

  bool _isDark = false;

  ThemeMode get currentMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeData _darkTheme = ThemeData.dark();
  ThemeData _lightTheme = ThemeData.light();

  ThemeData get dark => _darkTheme;
  ThemeData get light => _lightTheme;

  ArcaneReactiveTheme switchTheme(BuildContext context) {
    _isDark = !_isDark;
    notifyListeners();
    return I;
  }

  ArcaneReactiveTheme setDarkTheme(ThemeData theme) {
    _darkTheme = theme;
    notifyListeners();
    return I;
  }

  ArcaneReactiveTheme setLightTheme(ThemeData theme) {
    _lightTheme = theme;
    notifyListeners();
    return I;
  }
}

extension DarkMode on BuildContext {
  bool get isDarkMode {
    final brightness = MediaQuery.of(this).platformBrightness;
    return brightness == Brightness.dark;
  }
}
