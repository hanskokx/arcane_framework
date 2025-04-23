import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

/// A root widget for an Arcane-powered application.
///
/// `ArcaneApp` serves as the entry point for an application using the Arcane
/// framework. It provides access to the application's services and environment
/// settings throughout the widget tree using the `ArcaneServiceProvider` and
/// `ArcaneEnvironmentProvider`.
///
/// This widget wraps the provided [child] widget with the necessary providers
/// to make the Arcane services available to all descendant widgets.
///
/// Example usage:
/// ```dart
/// ArcaneApp(
///   services: [ArcaneAuthenticationService(), ArcaneFeatureFlags()],
///   child: MyApp(),
/// );
/// ```
class ArcaneApp extends StatefulWidget {
  /// A list of Arcane services that will be made available to the application.
  ///
  /// These services will be provided to the widget tree using
  /// `ArcaneServiceProvider`.
  /// If no services are specified, an empty list is used by default.
  final List<ArcaneService> services;

  /// The root widget of the application.
  ///
  /// This widget will be wrapped by the service and environment providers.
  final Widget child;

  /// Creates an `ArcaneApp` with the specified [child] widget and optional
  /// [services].
  ///
  /// The [child] is required, while the [services] list is optional. By
  /// default, the [services] list is empty.
  const ArcaneApp({
    required this.child,
    this.services = const [],
    super.key,
  });

  @override
  State<ArcaneApp> createState() => _ArcaneAppState();
}

class _ArcaneAppState extends State<ArcaneApp> with WidgetsBindingObserver {
  final GlobalKey _appKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ArcaneEnvironmentProvider(
      child: ArcaneServiceProvider(
        serviceInstances: widget.services,
        child: Builder(
          key: _appKey,
          builder: (BuildContext currentContext) {
            return StreamBuilder<ThemeMode>(
              stream: ArcaneReactiveTheme.I.currentThemeStream,
              initialData: ArcaneReactiveTheme.I.currentTheme,
              builder: (context, AsyncSnapshot<ThemeMode> snapshot) {
                final ThemeMode themeMode = snapshot.data ?? ThemeMode.light;

                return ArcaneTheme(
                  themeMode: themeMode,
                  child: widget.child,
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Register as an observer to detect system theme changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // When system brightness changes, find the current builder context
    // and use it to check the system theme
    if (mounted && _appKey.currentContext != null) {
      // Use the current context from the key to check system theme
      final BuildContext currentContext = _appKey.currentContext!;
      if (ArcaneReactiveTheme.I.isFollowingSystemTheme) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ArcaneReactiveTheme.I.checkSystemTheme(currentContext);
        });
      }
    }
    super.didChangePlatformBrightness();
  }
}
