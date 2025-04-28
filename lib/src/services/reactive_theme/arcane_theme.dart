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
}
