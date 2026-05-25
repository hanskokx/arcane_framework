import "package:arcane_framework/src/service/arcane_service.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";

import "arcane.dart";
import "services/environment/environment_provider.dart";
import "services/feature_flags/feature_flags_provider.dart";
import "services/theme/theme_switcher.dart";

/// A root widget for an Arcane-powered application.
///
/// `ArcaneApp` serves as the entry point for an application using the Arcane
/// framework. It provides access to the application's services and environment
/// settings throughout the widget tree using the `ArcaneServiceProvider`,
/// `ArcaneEnvironmentProvider`, and `ArcaneFeatureFlagsProvider`.
///
/// This widget wraps your app root with Arcane's built-in providers so
/// descendant widgets can access services, environment, feature flags, and
/// theme updates.
///
/// Preferred API: [builder]
///
/// Use [builder] when your app root needs a provider-aware `BuildContext`
/// during construction. This is the recommended and future-facing API.
///
/// Legacy API: [child]
///
/// [child] is deprecated but still supported for compatibility while migrating
/// existing apps.
///
/// Migration:
/// ```dart
/// // Before (deprecated)
/// ArcaneApp(child: MyApp())
///
/// // After (preferred)
/// ArcaneApp(builder: (context, _) => MyApp())
/// ```
///
/// Example usage:
/// ```dart
/// ArcaneApp(
///   services: [MyArcaneService()],
///   builder: (context, _) => MyApp(),
/// );
/// ```
class ArcaneApp extends StatefulWidget {
  /// A list of Arcane services that will be made available to the application.
  final List<ArcaneService> services;

  /// Optional builder invoked inside Arcane's provider tree.
  ///
  /// This mirrors Flutter's `TransitionBuilder` pattern and allows consumers
  /// to capture a provider-aware context without adding their own wrapper
  /// widgets around [child].
  final TransitionBuilder? builder;

  /// The root widget of the application.
  ///
  /// Deprecated: prefer [builder] to construct your root widget with a
  /// provider-aware BuildContext from inside `ArcaneApp`.
  @Deprecated(
    "Deprecated in 2.0.0. "
    "Prefer ArcaneApp.builder so your app root is built with Arcane-provided context.",
  )
  final Widget? child;

  /// A root widget for an Arcane-powered application.
  ///
  /// `ArcaneApp` serves as the entry point for an application using the Arcane
  /// framework. It provides access to the application's services and environment
  /// settings throughout the widget tree using the `ArcaneServiceProvider`,
  /// `ArcaneEnvironmentProvider`, and `ArcaneFeatureFlagsProvider`.
  ///
  /// This widget wraps your app root with Arcane's built-in providers so
  /// descendant widgets can access services, environment, feature flags, and
  /// theme updates.
  ///
  /// Preferred API: [builder]
  ///
  /// Use [builder] when your app root needs a provider-aware `BuildContext`
  /// during construction. This is the recommended and future-facing API.
  ///
  /// Legacy API: [child]
  ///
  /// [child] is deprecated but still supported for compatibility while migrating
  /// existing apps.
  ///
  /// Migration:
  /// ```dart
  /// // Before (deprecated)
  /// ArcaneApp(child: MyApp())
  ///
  /// // After (preferred)
  /// ArcaneApp(builder: (context, _) => MyApp())
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// ArcaneApp(
  ///   services: [MyArcaneService()],
  ///   builder: (context, _) => MyApp(),
  /// );
  /// ```
  const ArcaneApp({
    @Deprecated(
      "Deprecated in 2.0.0. "
      "Prefer ArcaneApp.builder so your app root is built with Arcane-provided context.",
    )
    this.child,
    this.services = const [],
    this.builder,
    super.key,
  }) : assert(
          child != null || builder != null,
          "ArcaneApp requires either a child or a builder.",
        );

  @override
  State<ArcaneApp> createState() => _ArcaneAppState();
}

class _ArcaneAppState extends State<ArcaneApp> {
  static const ListEquality<ArcaneService> _serviceListEquality =
      ListEquality<ArcaneService>(IdentityEquality<ArcaneService>());

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
  void didUpdateWidget(covariant ArcaneApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    final List<ArcaneService> mergedServices = _computeMergedServices();
    if (!_serviceListEquality.equals(_serviceNotifier.value, mergedServices)) {
      _serviceNotifier.value = mergedServices;
    }
  }

  @override
  void dispose() {
    Arcane.clearRegistry();
    _serviceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget appChild = widget.builder != null
        ? Builder(
            builder: (context) => widget.builder!(context, widget.child),
          )
        : widget.child!;

    return ArcaneServiceProvider(
      serviceNotifier: _serviceNotifier,
      child: ArcaneFeatureFlagsProvider(
        child: ArcaneEnvironmentProvider(
          child: ArcaneThemeSwitcher(
            child: appChild,
          ),
        ),
      ),
    );
  }
}
