library;

import "package:material_ui/material_ui.dart";

export "src/theme_extensions.dart";
export "src/theme_service.dart";
export "src/theme_switcher.dart";

class ArcaneTheme extends InheritedWidget {
  final ThemeMode themeMode;
  final bool followSystem;
  final ThemeData? theme;

  const ArcaneTheme({
    required super.child,
    super.key,
    this.themeMode = ThemeMode.light,
    this.followSystem = false,
    this.theme,
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
