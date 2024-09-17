import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

part "reactive_theme_extensions.dart";

/// A singleton service that manages theme switching and customization for the application.
///
/// `ArcaneReactiveTheme` allows switching between light and dark themes and provides
/// methods to customize the themes. The current theme mode can be accessed, and the
/// theme can be switched at runtime.
class ArcaneReactiveTheme extends ArcaneService {
  /// The singleton instance of `ArcaneReactiveTheme`.
  static final ArcaneReactiveTheme _instance = ArcaneReactiveTheme._internal();

  /// Provides access to the singleton instance of `ArcaneReactiveTheme`.
  static ArcaneReactiveTheme get I => _instance;

  ArcaneReactiveTheme._internal();

  /// Whether the current theme is dark.
  bool _isDark = false;

  /// Returns the current theme mode based on `_isDark`.
  ///
  /// If `_isDark` is true, it returns `ThemeMode.dark`, otherwise it returns `ThemeMode.light`.
  ThemeMode get currentMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// The `ThemeData` for the dark theme.
  ThemeData _darkTheme = ThemeData.dark();

  /// The `ThemeData` for the light theme.
  ThemeData _lightTheme = ThemeData.light();

  /// Returns the current dark theme `ThemeData`.
  ThemeData get dark => _darkTheme;

  /// Returns the current light theme `ThemeData`.
  ThemeData get light => _lightTheme;

  ValueListenable<ThemeMode> get systemTheme =>
      ValueNotifier<ThemeMode>(_isDark ? ThemeMode.dark : ThemeMode.light);

  /// Switches the current theme between light and dark modes.
  ///
  /// If the theme is currently light, it switches to dark, and vice versa. It also
  /// notifies listeners to update the UI accordingly.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.switchTheme(context);
  /// ```
  ArcaneReactiveTheme switchTheme(BuildContext context) {
    _isDark = !_isDark;
    notifyListeners();

    return I;
  }

  /// Switches the current theme between light and dark modes automatically
  /// based upon the system's current mode.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.followSystemTheme(context);
  /// final ThemeMode mode = Arcane.theme.systemTheme.value;
  /// ```
  ArcaneReactiveTheme followSystemTheme(BuildContext context) {
    final ThemeMode systemMode =
        context.isDarkMode ? ThemeMode.dark : ThemeMode.light;

    if (currentMode != systemMode) {
      _isDark = !_isDark;
      notifyListeners();
    }

    return I;
  }

  /// Sets a custom `ThemeData` for the dark theme.
  ///
  /// This allows you to customize the dark theme and notify listeners to apply the
  /// changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.setDarkTheme(customDarkTheme);
  /// ```
  ArcaneReactiveTheme setDarkTheme(ThemeData theme) {
    _darkTheme = theme;
    notifyListeners();
    return I;
  }

  /// Sets a custom `ThemeData` for the light theme.
  ///
  /// This allows you to customize the light theme and notify listeners to apply the
  /// changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.setLightTheme(customLightTheme);
  /// ```
  ArcaneReactiveTheme setLightTheme(ThemeData theme) {
    _lightTheme = theme;
    notifyListeners();
    return I;
  }
}
