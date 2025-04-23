import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

part "reactive_theme_extensions.dart";

/// A singleton service that manages theme switching and customization for the application.
///
/// `ArcaneReactiveTheme` allows switching between light and dark themes and provides
/// methods to customize the themes. The current theme mode can be accessed, and the
/// theme can be switched at runtime.
///
/// System theme changes are detected by the `ArcaneApp` widget, which ensures
/// theme updates happen automatically when the device theme changes.
class ArcaneReactiveTheme extends ArcaneService {
  /// The singleton instance of `ArcaneReactiveTheme`.
  static final ArcaneReactiveTheme _instance = ArcaneReactiveTheme._internal();

  /// Provides access to the singleton instance of `ArcaneReactiveTheme`.
  static ArcaneReactiveTheme get I => _instance;

  ArcaneReactiveTheme._internal();

  // Whether to follow system theme
  bool _followingSystemTheme = false;

  /// Whether the theme service is currently following the system theme.
  ///
  /// When true, the theme will automatically switch between light and dark
  /// based on the system's brightness setting.
  bool get isFollowingSystemTheme => _followingSystemTheme;

  final ValueNotifier<ThemeMode> _systemThemeNotifier =
      ValueNotifier(ThemeMode.system);

  final StreamController<ThemeMode> _themeStreamController =
      StreamController<ThemeMode>.broadcast(
    onCancel: () {
      I._themeStreamController.close();
    },
  );

  /// Stream of theme mode changes that can be listened to for reactive UI updates.
  Stream<ThemeMode> get currentThemeStream => I._themeStreamController.stream;

  ThemeMode _currentTheme = ThemeMode.light;

  /// The currently active theme mode (light or dark).
  ThemeMode get currentTheme => _currentTheme;

  /// A listenable that notifies listeners when the system theme mode changes.
  ThemeMode get systemTheme => I._systemThemeNotifier.value;

  /// The `ThemeData` for the dark theme.
  final ValueNotifier<ThemeData> _darkTheme = ValueNotifier(ThemeData.dark());

  /// The `ThemeData` for the light theme.
  final ValueNotifier<ThemeData> _lightTheme = ValueNotifier(ThemeData.light());

  /// Returns the current dark theme `ThemeData`.
  ThemeData get dark => _darkTheme.value;

  /// ValueNotifier for the dark theme that can be observed for changes.
  ValueNotifier<ThemeData> get darkTheme => I._darkTheme;

  /// Returns the current light theme `ThemeData`.
  ThemeData get light => _lightTheme.value;

  /// ValueNotifier for the light theme that can be observed for changes.
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
  /// This will also register for system theme changes, so the theme will
  /// automatically update when the system theme changes.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.followSystemTheme(context);
  /// ```
  ArcaneReactiveTheme followSystemTheme(BuildContext context) {
    _followingSystemTheme = true;

    // Always check the system theme when this method is called
    checkSystemTheme(context);

    return I;
  }

  /// Check and apply the system theme if we're following it
  ///
  /// This is called automatically when the system brightness changes if
  /// [followSystemTheme] has been enabled.
  void checkSystemTheme(BuildContext context) {
    if (!_followingSystemTheme) return;

    final Brightness systemBrightness =
        MediaQuery.platformBrightnessOf(context);

    final ThemeMode systemMode =
        systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    // Only update and notify if the theme actually changed
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

  /// Resets the theme service to its default state.
  ///
  /// This resets both light and dark themes to their default values and
  /// disables system theme following.
  @visibleForTesting
  void reset() {
    _darkTheme.value = ThemeData.dark();
    _lightTheme.value = ThemeData.light();
    _followingSystemTheme = false;
    _updateTheme(ThemeMode.light);
    notifyListeners();
  }

  /// Updates the current theme mode and broadcasts the change.
  void _updateTheme(ThemeMode themeMode) {
    _currentTheme = themeMode;
    _themeStreamController.add(themeMode);
  }
}
