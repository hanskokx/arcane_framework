import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

class ArcaneThemeSwitcher extends StatefulWidget {
  final Widget child;

  const ArcaneThemeSwitcher({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<ArcaneThemeSwitcher> createState() => _ArcaneThemeSwitcherState();
}

class _ArcaneThemeSwitcherState extends State<ArcaneThemeSwitcher> {
  late final StreamSubscription<ThemeMode> _themeModeSubscription;
  ThemeMode _currentThemeMode = ArcaneReactiveTheme.I.currentTheme;

  @override
  void initState() {
    super.initState();
    _themeModeSubscription =
        ArcaneReactiveTheme.I.themeChanges.listen((ThemeMode newMode) {
      if (mounted)
        setState(() {
          _currentThemeMode = newMode;
        });
    });
  }

  @override
  void dispose() {
    _themeModeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneTheme(
      themeMode: _currentThemeMode,
      child: widget.child,
    );
  }
}
