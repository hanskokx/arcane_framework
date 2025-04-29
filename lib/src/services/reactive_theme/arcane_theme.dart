import "package:flutter/material.dart";

class ArcaneTheme extends InheritedWidget {
  final ThemeMode themeMode;
  final bool followSystem;
  final ThemeData? theme;

  const ArcaneTheme({
    required super.child,
    this.themeMode = ThemeMode.light,
    this.followSystem = false,
    this.theme,
    super.key,
  });

  static ArcaneTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneTheme>();
  }

  @override
  bool updateShouldNotify(ArcaneTheme oldWidget) {
    return themeMode != oldWidget.themeMode ||
        followSystem != oldWidget.followSystem ||
        theme != oldWidget.theme;
  }
}
