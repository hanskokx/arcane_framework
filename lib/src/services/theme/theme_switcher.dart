import "dart:async";

import "package:flutter/material.dart";

import "arcane_theme.dart";
import "theme_service.dart";

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
  bool _initialized = false;
  late final StreamSubscription<ThemeMode> _themeModeSubscription;
  late final StreamSubscription<ThemeData> _themeSubscription;

  @override
  void initState() {
    super.initState();

    // Register as an observer to detect system theme changes
    WidgetsBinding.instance.addObserver(this);

    _themeModeSubscription = ArcaneThemeService.I.themeModeChanges.listen((_) {
      setState(() {});
    });
    _themeSubscription = ArcaneThemeService.I.themeDataChanges.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_themeModeSubscription.cancel());
    unawaited(_themeSubscription.cancel());

    // Clean up the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ArcaneThemeService.I.setInitialTheme(context);

      // ArcaneApp defaults to following the platform theme until the user
      // explicitly picks a manual light/dark mode.
      ArcaneThemeService.I.followSystemTheme(context);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneTheme(
      themeMode: ArcaneThemeService.I.currentThemeMode,
      followSystem: ArcaneThemeService.I.isFollowingSystemTheme,
      theme: ArcaneThemeService.I.currentTheme,
      child: widget.child,
    );
  }

  @override
  void didChangePlatformBrightness() {
    // When system brightness changes, find the current builder context
    // and use it to check the system theme
    if (mounted) {
      // Use the current context from the key to check system theme
      if (ArcaneThemeService.I.isFollowingSystemTheme) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ArcaneThemeService.I.followSystemTheme(context);
        });
      }
    }
    super.didChangePlatformBrightness();
  }
}
