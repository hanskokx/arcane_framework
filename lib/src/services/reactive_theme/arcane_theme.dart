import "dart:async";

import "package:arcane_framework/src/services/reactive_theme/reactive_theme_service.dart";
import "package:flutter/material.dart";

class ArcaneTheme extends InheritedWidget {
  final ThemeMode themeMode;
  final bool followSystem;

  const ArcaneTheme({
    required this.themeMode,
    required this.followSystem,
    required super.child,
    super.key,
  });

  static ArcaneTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneTheme>();
  }

  @override
  bool updateShouldNotify(ArcaneTheme oldWidget) {
    return themeMode != oldWidget.themeMode ||
        followSystem != oldWidget.followSystem;
  }

  /// Returns the singleton instance of the [ArcaneReactiveTheme] service.
  ArcaneReactiveTheme get service => ArcaneReactiveTheme.I;

  /// Indicates whether the theme is currently set to follow the system theme.
  bool get isFollowingSystemTheme => service.isFollowingSystemTheme;

  /// Provides a stream of [ThemeMode] changes that can be listened to for reactive updates.
  Stream<ThemeMode> get themeChanges => service.themeChanges;

  /// Returns the currently active [ThemeMode].
  ThemeMode get currentTheme => service.currentTheme;

  /// Returns the [ThemeMode] currently set at the OS/system level.
  ThemeMode get systemTheme => service.systemTheme;

  /// Returns the dark [ThemeData] configuration.
  ThemeData get dark => service.dark;

  /// Returns a [ValueNotifier] containing the dark [ThemeData], allowing for reactive updates.
  ValueNotifier<ThemeData> get darkTheme => service.darkTheme;

  /// Returns the light [ThemeData] configuration.
  ThemeData get light => service.light;

  /// Returns a [ValueNotifier] containing the light [ThemeData], allowing for reactive updates.
  ValueNotifier<ThemeData> get lightTheme => service.lightTheme;

  /// A shortcut to the [ArcaneReactiveTheme] function that switches the active theme mode.
  ///
  /// - [themeMode] (Optional): Specify which theme mode to switch to.
  ///   Otherwise, tries to determine whether to switch to light or dark mode, automatically.
  ArcaneReactiveTheme Function({ThemeMode? themeMode}) get switchTheme =>
      service.switchTheme;

  /// A shortcut to the [ArcaneReactiveTheme] function that follows the system theme.
  ///
  /// - [context]: The [BuildContext] required to access system theme information.
  void Function(BuildContext context) followSystemTheme(
    BuildContext context,
  ) =>
      service.followSystemTheme;

  /// A shortcut to the [ArcaneReactiveTheme] function that updates the dark theme configuration.
  ///
  /// The function accepts a [ThemeData] parameter to set as the new dark theme.
  ArcaneReactiveTheme Function(ThemeData theme) get setDarkTheme =>
      service.setDarkTheme;

  /// A shortcut to the [ArcaneReactiveTheme] function that updates the light theme configuration.
  ///
  /// The function accepts a [ThemeData] parameter to set as the new light theme.
  ArcaneReactiveTheme Function(ThemeData theme) get setLightTheme =>
      service.setLightTheme;
}
