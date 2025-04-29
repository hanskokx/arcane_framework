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
  /// When `true`, the theme will automatically switch between light and dark
  /// based on the system's brightness setting.
  bool get isFollowingSystemTheme => _followingSystemTheme;

  final StreamController<ThemeMode> _systemStreamController =
      StreamController<ThemeMode>.broadcast(
    onCancel: () {
      I._systemStreamController.close();
    },
  );

  final StreamController<ThemeMode> _themeModeStreamController =
      StreamController<ThemeMode>.broadcast(
    onCancel: () {
      I._themeModeStreamController.close();
    },
  );

  final StreamController<ThemeData> _themeStreamController =
      StreamController<ThemeData>.broadcast(
    onCancel: () {
      I._themeStreamController.close();
    },
  );

  /// Stream of `ThemeMode` changes that can be listened to for reactive UI updates.
  Stream<ThemeMode> get themeModeChanges => I._themeModeStreamController.stream;

  /// Stream of `ThemeData` changes that can be listened to for reactive UI updates.
  Stream<ThemeData> get themeDataChanges => I._themeStreamController.stream;

  /// Returns the `ThemeData` corresponding to the current system theme
  ThemeMode get systemThemeMode => _currentSystemThemeMode;

  /// Tracks the current system theme mode
  ThemeMode _currentSystemThemeMode = ThemeMode.system;

  ThemeMode _currentThemeMode = ThemeMode.light;

  /// The currently active theme mode (light or dark).
  ThemeMode get currentThemeMode => _currentThemeMode;

  ThemeData _currentTheme = ThemeData();

  /// The currently active theme style.
  ThemeData get currentTheme => _currentTheme;

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

  /// Returns the current `ThemeMode` being used by `ArcaneReactiveTheme`.
  /// Will automatically update when the theme changes.
  ThemeMode currentModeOf(BuildContext context) => context.themeMode;

  /// Switches the current theme between light and dark modes.
  ///
  /// If the theme is currently light, it switches to dark, and vice versa. It
  /// also notifies listeners to update the UI accordingly.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.switchTheme();
  /// // or
  /// ArcaneReactiveTheme.I.switchTheme(themeMode: ThemeMode.dark);
  /// // or
  /// Arcane.theme.switchTheme(themeMode: ThemeMode.light);
  /// ```
  ArcaneReactiveTheme switchTheme({ThemeMode? themeMode}) {
    _followingSystemTheme = false;

    if (themeMode != null) {
      _updateTheme(themeMode);
    } else {
      _updateTheme(
        currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
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
  /// // or
  /// Arcane.theme.followSystemTheme(context);
  /// ```
  ArcaneReactiveTheme followSystemTheme(BuildContext context) {
    _followingSystemTheme = true;

    _currentSystemThemeMode =
        context.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _systemStreamController.add(_currentSystemThemeMode);
    _updateTheme(_currentSystemThemeMode);

    final ThemeData theme = systemThemeMode == ThemeMode.dark ? dark : light;
    _themeStreamController.add(theme);
    _currentTheme = theme;
    notifyListeners();

    return I;
  }

  /// Sets a custom `ThemeData` for the dark theme.
  ///
  /// This allows you to customize the dark theme and notify listeners to apply
  /// the changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.setDarkTheme(customDarkTheme);
  /// ```
  ArcaneReactiveTheme setDarkTheme(ThemeData theme) {
    _darkTheme.value = theme;
    _themeStreamController.add(theme);
    _currentTheme = theme;
    notifyListeners();
    return I;
  }

  /// Sets a custom `ThemeData` for the light theme.
  ///
  /// This allows you to customize the light theme and notify listeners to apply
  /// the changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneReactiveTheme.I.setLightTheme(customLightTheme);
  /// ```
  ArcaneReactiveTheme setLightTheme(ThemeData theme) {
    _lightTheme.value = theme;
    _themeStreamController.add(theme);
    _currentTheme = theme;
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
    _themeStreamController.add(_lightTheme.value);
    _currentTheme = _lightTheme.value;
    notifyListeners();
  }

  /// Updates the current theme mode and broadcasts the change.
  void _updateTheme(ThemeMode themeMode) {
    _currentThemeMode = themeMode;
    _themeModeStreamController.add(themeMode);
  }
}
