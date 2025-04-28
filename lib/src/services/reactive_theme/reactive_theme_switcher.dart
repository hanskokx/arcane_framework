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
  late final StreamSubscription<ThemeMode> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ArcaneReactiveTheme.I.themeChanges.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneTheme(
      themeMode: ArcaneReactiveTheme.I.currentTheme,
      followSystem: ArcaneReactiveTheme.I.isFollowingSystemTheme,
      child: widget.child,
    );
  }
}
