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
  late final StreamSubscription<ThemeData> _themeSubscription;

  @override
  void initState() {
    super.initState();
    _themeModeSubscription = ArcaneReactiveTheme.I.themeModeChanges.listen((_) {
      setState(() {});
    });
    _themeSubscription = ArcaneReactiveTheme.I.themeDataChanges.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeModeSubscription.cancel();
    _themeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneTheme(
      themeMode: ArcaneReactiveTheme.I.currentThemeMode,
      followSystem: ArcaneReactiveTheme.I.isFollowingSystemTheme,
      theme: ArcaneReactiveTheme.I.currentTheme,
      child: widget.child,
    );
  }
}
