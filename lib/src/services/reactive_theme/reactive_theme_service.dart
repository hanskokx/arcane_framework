import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
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
  ArcaneReactiveTheme._internal();
  static final ArcaneReactiveTheme _instance = ArcaneReactiveTheme._internal();
  static ArcaneReactiveTheme get I => _instance;

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

  final ValueNotifier<ThemeMode> _systemThemeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  // ************************************************************************ //
  // * MARK: ThemeMode
  // ************************************************************************ //
  /// Returns the current `ThemeMode` being used by `ArcaneReactiveTheme`.
  /// Will automatically update when the theme changes.
  ThemeMode currentModeOf(BuildContext context) => context.themeMode;

  /// The currently active theme mode (light or dark).
  ThemeMode get currentThemeMode => _currentThemeMode;
  ThemeMode _currentThemeMode = ThemeMode.light;

  /// ValueListenable of `ThemeMode` changes that can be listened to for reactive UI updates.
  ValueListenable<ThemeMode> get themeModeChanges => I._themeModeNotifier;

  final ValueNotifier<ThemeMode> _themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  // ************************************************************************ //
  // * MARK: ThemeData
  // ************************************************************************ //
  /// The currently active theme style.
  ThemeData get currentTheme => _currentTheme;
  ThemeData _currentTheme = ThemeData.light();

  /// ValueListenable of `ThemeData` changes that can be listened to for reactive UI updates.
  ValueListenable<ThemeData> get themeDataChanges => I._themeNotifier;

  final ValueNotifier<ThemeData> _themeNotifier =
      ValueNotifier<ThemeData>(ThemeData.light());

  /// ValueListenable that rebuilds when the effective theme changes.
  /// This includes theme mode changes and active theme data changes.
  /// Use this for most UI components that need to react to theme changes.
  ValueListenable<ThemeData> get effectiveThemeChanges =>
      I._effectiveThemeNotifier;

  final ValueNotifier<ThemeData> _effectiveThemeNotifier =
      ValueNotifier<ThemeData>(ThemeData.light());

  /// ValueListenable that notifies when the system theme following state changes.
  ValueListenable<bool> get followingSystemThemeChanges =>
      I._followingSystemThemeNotifier;

  final ValueNotifier<bool> _followingSystemThemeNotifier =
      ValueNotifier<bool>(false);

  /// Combined Listenable that merges all theme-related changes.
  /// Use this for widgets that need to rebuild on any theme change.
  Listenable get themeChanges => I._combinedThemeListenable;

  late final Listenable _combinedThemeListenable = Listenable.merge([
    _effectiveThemeNotifier,
    _followingSystemThemeNotifier,
    _themeModeNotifier,
  ]);

  // ************************************************************************ //
  // * MARK: Light/Dark theme
  // ************************************************************************ //
  /// Returns the current dark theme `ThemeData`.
  ThemeData get dark => _darkTheme.value;

  /// ValueNotifier for the dark theme that can be observed for changes.
  ValueNotifier<ThemeData> get darkTheme => I._darkTheme;
  final ValueNotifier<ThemeData> _darkTheme = ValueNotifier(ThemeData.dark());

  /// Returns the current light theme `ThemeData`.
  ThemeData get light => _lightTheme.value;

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
  /// ArcaneReactiveTheme.I.switchTheme();
  /// // or
  /// ArcaneReactiveTheme.I.switchTheme(themeMode: ThemeMode.dark);
  /// // or
  /// Arcane.theme.switchTheme(themeMode: ThemeMode.light);
  /// ```
  ArcaneReactiveTheme switchTheme({ThemeMode? themeMode}) {
    _followingSystemTheme = false;
    _followingSystemThemeNotifier.value = false;

    if (themeMode != null) {
      _updateTheme(themeMode);
    } else {
      _updateTheme(
        currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
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
  /// ArcaneReactiveTheme.I.followSystemTheme(context);
  /// // or
  /// Arcane.theme.followSystemTheme(context);
  /// ```
  ArcaneReactiveTheme followSystemTheme(BuildContext context) {
    _followingSystemTheme = true;
    _followingSystemThemeNotifier.value = true;

    _currentSystemThemeMode =
        context.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _systemThemeNotifier.value = _currentSystemThemeMode;
    _updateTheme(_currentSystemThemeMode);

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

    // Only update current theme if we're currently in dark mode
    if (_currentThemeMode == ThemeMode.dark) {
      _themeNotifier.value = theme;
      _currentTheme = theme;
      _effectiveThemeNotifier.value = theme;
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
  /// ArcaneReactiveTheme.I.setLightTheme(customLightTheme);
  /// ```
  ArcaneReactiveTheme setLightTheme(ThemeData theme) {
    _lightTheme.value = theme;

    // Only update current theme if we're currently in light mode
    if (_currentThemeMode == ThemeMode.light) {
      _themeNotifier.value = theme;
      _currentTheme = theme;
      _effectiveThemeNotifier.value = theme;
    }

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
    _followingSystemThemeNotifier.value = false;
    _updateTheme(ThemeMode.light);
    _themeNotifier.value = _lightTheme.value;
    _currentTheme = _lightTheme.value;
    _effectiveThemeNotifier.value = _lightTheme.value;
  }

  /// Updates the current theme mode and broadcasts the change.
  void _updateTheme(ThemeMode themeMode) {
    _currentThemeMode = themeMode;
    _themeModeNotifier.value = themeMode;

    // Update the current theme data based on the theme mode
    final ThemeData newTheme = themeMode == ThemeMode.dark ? dark : light;
    _currentTheme = newTheme;
    _themeNotifier.value = newTheme;
    _effectiveThemeNotifier.value = newTheme;
  }

  /// Disposes of the theme service resources.
  ///
  /// This method should be called when the service is no longer needed
  /// to clean up ValueNotifiers and prevent memory leaks.
  @override
  void dispose() {
    _systemThemeNotifier.dispose();
    _themeModeNotifier.dispose();
    _themeNotifier.dispose();
    _effectiveThemeNotifier.dispose();
    _followingSystemThemeNotifier.dispose();
    _darkTheme.dispose();
    _lightTheme.dispose();
    super.dispose();
  }
}
