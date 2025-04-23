import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

part "reactive_theme_extensions.dart";

/// A singleton service that manages theme switching and customization for the application.
///
/// `ArcaneReactiveTheme` allows switching between light and dark themes and provides
/// methods to customize the themes. The current theme mode can be accessed, and the
/// theme can be switched at runtime.
class ArcaneReactiveTheme extends ArcaneService with WidgetsBindingObserver {
  /// The singleton instance of `ArcaneReactiveTheme`.
  static final ArcaneReactiveTheme _instance = ArcaneReactiveTheme._internal();

  /// Provides access to the singleton instance of `ArcaneReactiveTheme`.
  static ArcaneReactiveTheme get I => _instance;

  ArcaneReactiveTheme._internal();

  // Whether to follow system theme
  bool _followingSystemTheme = false;

  final ValueNotifier<ThemeMode> _systemThemeNotifier =
      ValueNotifier(ThemeMode.system);

  final StreamController<ThemeMode> _themeStreamController =
      StreamController<ThemeMode>.broadcast(
    onCancel: () {
      I._themeStreamController.close();
    },
  );

  Stream<ThemeMode> get currentThemeStream => I._themeStreamController.stream;

  ThemeMode _currentTheme = ThemeMode.light;

  ThemeMode get currentTheme => _currentTheme;

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
    _followingSystemTheme = false;

    if (themeMode != null) {
      _updateTheme(themeMode);
    } else {
      _updateTheme(
        currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
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
    if (!_followingSystemTheme) {
      _followingSystemTheme = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkSystemTheme(context);
      });
    }

    return I;
  }

  /// Check and apply the system theme if we're following it
  void checkSystemTheme(BuildContext context) {
    if (!_followingSystemTheme) return;

    final Brightness systemBrightness =
        MediaQuery.platformBrightnessOf(context);

    final ThemeMode systemMode =
        systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    if (systemMode != _currentTheme) {
      _updateTheme(systemMode);
      notifyListeners();
    }
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
    _followingSystemTheme = false;
    _updateTheme(ThemeMode.light);
    notifyListeners();
  }

  void _updateTheme(ThemeMode themeMode) {
    _currentTheme = themeMode;
    _themeStreamController.add(themeMode);
  }
}
