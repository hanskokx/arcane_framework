import "package:arcane_framework/arcane_framework.dart";
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

  final ValueNotifier<ThemeMode> _systemThemeNotifier =
      ValueNotifier(ThemeMode.light);

  final ValueNotifier<ThemeMode> _currentThemeNotifier =
      ValueNotifier(ThemeMode.light);

  ThemeMode get currentTheme => I._currentThemeNotifier.value;

  /// A listenable that notifies listeners when the system theme mode changes.
  ThemeMode get systemTheme => I._systemThemeNotifier.value;

  /// The `ThemeData` for the dark theme.
  final ValueNotifier<ThemeData> _darkTheme = ValueNotifier(ThemeData.dark());

  /// The `ThemeData` for the light theme.
  final ValueNotifier<ThemeData> _lightTheme = ValueNotifier(ThemeData.light());

  /// Returns the current dark theme `ThemeData`.
  ThemeData get dark => _darkTheme.value;
  ValueNotifier<ThemeData> get darkTheme => I._darkTheme;

  /// Returns the current light theme `ThemeData`.
  ThemeData get light => _lightTheme.value;
  ValueNotifier<ThemeData> get lightTheme => I._lightTheme;

  /// Switches the current theme between light and dark modes.
  ///
  /// If the theme is currently light, it switches to dark, and vice versa. It also
  /// notifies listeners to update the UI accordingly.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.switchTheme();
  /// ```
  ArcaneReactiveTheme switchTheme({ThemeMode? themeMode}) {
    if (I._systemThemeNotifier.hasListeners) {
      _systemThemeNotifier.removeListener(_systemThemeListener);
    }

    if (themeMode != null) {
      _currentThemeNotifier.value = themeMode;
    } else {
      _currentThemeNotifier.value =
          _currentThemeNotifier.value == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
    }

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

    if (!I._systemThemeNotifier.hasListeners) {
      I._systemThemeNotifier.addListener(_systemThemeListener);
    }

    if (systemMode != currentTheme) {
      _systemThemeNotifier.value = systemMode;
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
    _darkTheme.value = theme;
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
    _lightTheme.value = theme;
    notifyListeners();
    return I;
  }

  @visibleForTesting
  void reset() {
    _darkTheme.value = ThemeData.dark();
    _lightTheme.value = ThemeData.light();
    _systemThemeNotifier.value = ThemeMode.light;
    _currentThemeNotifier.value = ThemeMode.light;
    notifyListeners();
  }

  void _systemThemeListener() {
    if (currentTheme != _systemThemeNotifier.value) {
      _currentThemeNotifier.value = _systemThemeNotifier.value;
      notifyListeners();
    }
  }
}
