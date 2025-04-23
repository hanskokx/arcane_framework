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
          builder: (context) {
            _updateContextReference(context);

            return StreamBuilder<ThemeMode>(
              stream: ArcaneReactiveTheme.I.currentThemeStream,
              builder: (context, AsyncSnapshot<ThemeMode> snapshot) {
                if (!snapshot.hasData) return widget.child;

                return KeyedSubtree(
                  key: Key(snapshot.data!.name),
                  child: widget.child,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Update our context reference whenever the widget is built
  void _updateContextReference(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only store this context if the widget is still mounted
      if (mounted) {
        // Store this context in a way that ArcaneReactiveTheme can access it
        ArcaneReactiveTheme.I.checkSystemTheme(context);
      }
    });
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
    // This is called when the system brightness changes
    // Check and update the theme if we're following system theme
    ArcaneReactiveTheme.I.checkSystemTheme(context);
    super.didChangePlatformBrightness();
  }
}
