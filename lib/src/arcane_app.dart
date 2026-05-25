import "package:arcane_framework/src/service/arcane_service.dart";
import "package:flutter/material.dart";

import "arcane.dart";
import "services/environment/environment_provider.dart";
import "services/feature_flags/feature_flags_provider.dart";
import "services/theme/theme_switcher.dart";

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
///   services: [MyArcaneService()],
///   child: MyApp(),
/// );
/// ```
class ArcaneApp extends StatefulWidget {
  /// A list of Arcane services that will be made available to the application.
  final List<ArcaneService> services;

  /// The root widget of the application.
  final Widget child;

  /// Creates an `ArcaneApp` with the specified [child] widget and optional [services].
  const ArcaneApp({
    required this.child,
    this.services = const [],
    super.key,
  });

  @override
  State<ArcaneApp> createState() => _ArcaneAppState();
}

class _ArcaneAppState extends State<ArcaneApp> {
  late final ValueNotifier<List<ArcaneService>> _serviceNotifier;

  List<ArcaneService> _computeMergedServices() {
    final List<ArcaneService> merged =
        List<ArcaneService>.from(widget.services);
    final Set<Type> existingTypes =
        merged.map((service) => service.runtimeType).toSet();

    // Use Arcane._builtInServices directly to avoid registry recursion during init.
    for (final ArcaneService builtIn in Arcane.builtInServices) {
      if (existingTypes.contains(builtIn.runtimeType)) continue;
      merged.add(builtIn);
      existingTypes.add(builtIn.runtimeType);
    }

    return merged;
  }

  @override
  void initState() {
    super.initState();
    _serviceNotifier =
        ValueNotifier<List<ArcaneService>>(_computeMergedServices());
    Arcane.setRegistry(_serviceNotifier);
  }

  @override
  void dispose() {
    Arcane.clearRegistry();
    _serviceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneServiceProvider(
      serviceNotifier: _serviceNotifier,
      child: ArcaneFeatureFlagsProvider(
        child: ArcaneEnvironmentProvider(
          child: ArcaneThemeSwitcher(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
