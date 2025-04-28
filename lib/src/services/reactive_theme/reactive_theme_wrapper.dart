import "dart:async";

import "package:arcane_framework/src/services/reactive_theme/reactive_theme_service.dart";
import "package:flutter/material.dart";

class ArcaneTheme extends InheritedWidget {
  final ThemeMode themeMode;

  const ArcaneTheme({
    required this.themeMode,
    required super.child,
    super.key,
  });

  static ArcaneTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneTheme>();
  }

  @override
  bool updateShouldNotify(ArcaneTheme oldWidget) {
    return themeMode != oldWidget.themeMode;
  }

  static ArcaneReactiveTheme get service => ArcaneReactiveTheme.I;
  static bool get isFollowingSystemTheme => service.isFollowingSystemTheme;
  static Stream<ThemeMode> get themeChanges => service.themeChanges;
  static ThemeMode get currentTheme => service.currentTheme;
  static ThemeMode get systemTheme => service.systemTheme;
  static ThemeData get dark => service.dark;
  static ValueNotifier<ThemeData> get darkTheme => service.darkTheme;
  static ThemeData get light => service.light;
  static ValueNotifier<ThemeData> get lightTheme => service.lightTheme;

  static ArcaneReactiveTheme Function({ThemeMode? themeMode}) get switchTheme =>
      service.switchTheme;
  static ArcaneReactiveTheme Function(BuildContext context)
      get followSystemTheme => service.followSystemTheme;
  static ArcaneReactiveTheme Function(ThemeData theme) get setDarkTheme =>
      service.setDarkTheme;
  static ArcaneReactiveTheme Function(ThemeData theme) get setLightTheme =>
      service.setLightTheme;
}
