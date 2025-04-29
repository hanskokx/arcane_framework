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
class ArcaneApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ArcaneEnvironmentProvider(
      child: ArcaneServiceProvider(
        serviceInstances: services,
        child: ArcaneThemeSwitcher(
          child: child,
        ),
      ),
    );
  }
}
