import "dart:async";

import "package:arcane_framework/src/service/arcane_service.dart";
import "package:flutter/material.dart";

import "theme_extensions.dart";

@Deprecated(
  "Deprecated in 2.0.0. "
  "ArcaneReactiveTheme has been renamed to ArcaneThemeService for clarity. "
  "Please use ArcaneThemeService instead.",
)
typedef ArcaneReactiveTheme = ArcaneThemeService;

/// A singleton service that manages theme switching and customization for the application.
///
/// `ArcaneThemeService` allows switching between light and dark themes and provides
/// methods to customize the themes. The current theme mode can be accessed, and the
/// theme can be switched at runtime.
///
/// System theme changes are detected by the `ArcaneApp` widget, which ensures
/// theme updates happen automatically when the device theme changes.
class ArcaneThemeService extends ArcaneService {
  ArcaneThemeService._internal();
  static final ArcaneThemeService _instance = ArcaneThemeService._internal();
  static ArcaneThemeService get I => _instance;

  // ************************************************************************ //
  // * MARK: System theme
  // ************************************************************************ //
  /// Whether the theme service is currently following the system theme.
  ///
  /// When `true`, the theme will automatically switch between light and dark
  /// based on the system's brightness setting.
  bool get isFollowingSystemTheme => _followingSystemTheme;
  bool _followingSystemTheme = false;

  /// Returns the `ThemeData` corresponding to the current system theme
  ThemeMode get systemThemeMode => _currentSystemThemeMode;

  /// Tracks the current system theme mode
  ThemeMode _currentSystemThemeMode = ThemeMode.system;

  StreamController<ThemeMode>? _systemStreamController;

  StreamController<ThemeMode> get _systemController {
    _systemStreamController ??= StreamController<ThemeMode>.broadcast();
    return _systemStreamController!;
  }

  // ************************************************************************ //
  // * MARK: ThemeMode
  // ************************************************************************ //
  /// Returns the current `ThemeMode` being used by `ArcaneThemeService`.
  /// Will automatically update when the theme changes.
  ThemeMode currentModeOf(BuildContext context) => context.themeMode;

  /// The currently active theme mode (light, dark, or system) as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [themeModeChanges] when you need reactive updates.
  ///
  /// If `ThemeMode.system`, the effective theme is determined by the platform brightness.
  ThemeMode get currentThemeMode => _currentThemeMode;
  ThemeMode _currentThemeMode = ThemeMode.system;

  /// Stream of `ThemeMode` changes that can be listened to for reactive UI updates.
  Stream<ThemeMode> get themeModeChanges => I._themeModeController.stream;

  StreamController<ThemeMode>? _themeModeStreamController;

  StreamController<ThemeMode> get _themeModeController {
    _themeModeStreamController ??= StreamController<ThemeMode>.broadcast();
    return _themeModeStreamController!;
  }

  // ************************************************************************ //
  // * MARK: ThemeData
  // ************************************************************************ //
  /// The currently active theme style as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [themeDataChanges] when you need reactive updates.
  ThemeData get currentTheme => _currentTheme;
  ThemeData _currentTheme = ThemeData();

  /// Stream of `ThemeData` changes that can be listened to for reactive UI updates.
  Stream<ThemeData> get themeDataChanges => I._themeController.stream;

  /// Tracks whether a custom light/dark theme has been explicitly provided by the user.
  bool _themeOverriddenByUser = false;

  StreamController<ThemeData>? _themeStreamController;

  StreamController<ThemeData> get _themeController {
    _themeStreamController ??= StreamController<ThemeData>.broadcast();
    return _themeStreamController!;
  }

  // ************************************************************************ //
  // * MARK: Light/Dark theme
  // ************************************************************************ //
  /// Returns the current dark theme `ThemeData` as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [darkTheme] when you need reactive updates.
  ThemeData get dark => _darkTheme.value;

  /// Sets a custom dark `ThemeData`.
  ///
  /// This is a convenience setter that delegates to [setDarkTheme].
  set dark(ThemeData theme) => setDarkTheme(theme);

  /// ValueNotifier for the dark theme that can be observed for changes.
  ValueNotifier<ThemeData> get darkTheme => I._darkTheme;
  final ValueNotifier<ThemeData> _darkTheme = ValueNotifier(ThemeData.dark());

  /// Returns the current light theme `ThemeData` as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [lightTheme] when you need reactive updates.
  ThemeData get light => _lightTheme.value;

  /// Sets a custom light `ThemeData`.
  ///
  /// This is a convenience setter that delegates to [setLightTheme].
  set light(ThemeData theme) => setLightTheme(theme);

  /// ValueNotifier for the light theme that can be observed for changes.
  ValueNotifier<ThemeData> get lightTheme => I._lightTheme;
  final ValueNotifier<ThemeData> _lightTheme = ValueNotifier(ThemeData.light());

  // ************************************************************************ //
  // * MARK: Methods
  // ************************************************************************ //
  /// Switches the current theme between light and dark modes.
  ///
  /// If the theme is currently light, it switches to dark, and vice versa. It
  /// also notifies listeners to update the UI accordingly.
  ///
  /// Example:
  /// ```dart
  /// ArcaneThemeService.I.switchTheme();
  /// // or
  /// ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.dark);
  /// // or
  /// Arcane.theme.switchTheme(themeMode: ThemeMode.light);
  /// ```
  ArcaneThemeService switchTheme({ThemeMode? themeMode}) {
    _followingSystemTheme = false;

    if (themeMode != null) {
      _updateTheme(themeMode);
    } else {
      final ThemeMode effectiveMode = _effectiveThemeMode;
      _updateTheme(
        effectiveMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
    }

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
  /// ArcaneThemeService.I.followSystemTheme(context);
  /// // or
  /// Arcane.theme.followSystemTheme(context);
  /// ```
  ArcaneThemeService followSystemTheme(BuildContext context) {
    _followingSystemTheme = true;

    _currentSystemThemeMode =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
    _systemController.add(_currentSystemThemeMode);
    _updateTheme(_currentSystemThemeMode);

    final ThemeData theme = systemThemeMode == ThemeMode.dark ? dark : light;
    _themeController.add(theme);
    _currentTheme = theme;

    return I;
  }

  /// Sets a custom `ThemeData` for the dark theme.
  ///
  /// This allows you to customize the dark theme and notify listeners to apply
  /// the changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneThemeService.I.setDarkTheme(customDarkTheme);
  /// ```
  ArcaneThemeService setDarkTheme(ThemeData theme) {
    _themeOverriddenByUser = true;
    _darkTheme.value = theme;
    // Only update the rendered theme if dark is the active mode.
    if (_effectiveThemeMode == ThemeMode.dark) {
      _themeController.add(theme);
      _currentTheme = theme;
    }
    return I;
  }

  /// Sets a custom `ThemeData` for the light theme.
  ///
  /// This allows you to customize the light theme and notify listeners to apply
  /// the changes immediately.
  ///
  /// Example:
  /// ```dart
  /// ArcaneThemeService.I.setLightTheme(customLightTheme);
  /// ```
  ArcaneThemeService setLightTheme(ThemeData theme) {
    _themeOverriddenByUser = true;
    _lightTheme.value = theme;
    // Only update the rendered theme if light is the active mode.
    if (_effectiveThemeMode == ThemeMode.light) {
      _themeController.add(theme);
      _currentTheme = theme;
    }
    return I;
  }

  /// Should be called on first build to ensure the initial theme matches the platform brightness.
  void setInitialTheme(BuildContext context) {
    // Only update when no custom theme was explicitly provided by the user.
    if (_themeOverriddenByUser) {
      return;
    }
    switch (_currentThemeMode) {
      case ThemeMode.system:
        final isDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        _currentTheme = isDark ? ThemeData.dark() : ThemeData.light();
      case ThemeMode.dark:
        _currentTheme = ThemeData.dark();
      case ThemeMode.light:
        _currentTheme = ThemeData.light();
    }
  }

  /// Resets the theme service to its default state.
  ///
  /// This resets both light and dark themes to their default values and
  /// disables system theme following.
  @visibleForTesting
  void reset() {
    _darkTheme.value = ThemeData.dark();
    _lightTheme.value = ThemeData.light();
    _themeOverriddenByUser = false;
    _followingSystemTheme = false;
    _updateTheme(ThemeMode.light);
    _themeController.add(_lightTheme.value);
    _currentTheme = _lightTheme.value;
  }

  @override
  void dispose() {
    unawaited(_systemStreamController?.close());
    unawaited(_themeModeStreamController?.close());
    unawaited(_themeStreamController?.close());

    _systemStreamController = null;
    _themeModeStreamController = null;
    _themeStreamController = null;

    super.dispose();
  }

  /// Updates the current theme mode and broadcasts the change.
  void _updateTheme(ThemeMode themeMode) {
    _currentThemeMode = themeMode;
    _themeModeController.add(themeMode);
  }

  ThemeMode get _effectiveThemeMode {
    if (_currentThemeMode != ThemeMode.system) {
      return _currentThemeMode;
    }

    return _currentTheme.brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
