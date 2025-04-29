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

class _ArcaneThemeSwitcherState extends State<ArcaneThemeSwitcher>
    with WidgetsBindingObserver {
  late final StreamSubscription<ThemeMode> _themeModeSubscription;
  late final StreamSubscription<ThemeData> _themeSubscription;

  @override
  void initState() {
    super.initState();
    // Register as an observer to detect system theme changes
    WidgetsBinding.instance.addObserver(this);

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
    // Clean up the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangePlatformBrightness() {
    // When system brightness changes, find the current builder context
    // and use it to check the system theme
    if (mounted) {
      // Use the current context from the key to check system theme
      if (ArcaneReactiveTheme.I.isFollowingSystemTheme) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ArcaneReactiveTheme.I.followSystemTheme(context);
        });
      }
    }
    super.didChangePlatformBrightness();
  }
}
