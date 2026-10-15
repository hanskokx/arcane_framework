import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";

import "arcane.dart";
import "environment_provider.dart";
import "extension/arcane_service_extensions.dart";
import "feature_flags/feature_flags_provider.dart";
import "service_provider.dart";

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
/// ArcaneApp(builder: (context) => MyApp())
/// ```
///
/// Example usage:
/// ```dart
/// ArcaneApp(
///   services: [MyArcaneService()],
///   builder: (context) => MyApp(),
/// );
/// ```
class ArcaneApp extends StatefulWidget {
  /// A list of Arcane services that will be made available to the application.
  final List<ArcaneService> services;

  /// Optional builder invoked inside Arcane's provider tree.
  ///
  /// This mirrors Flutter's `WidgetBuilder` pattern and allows consumers
  /// to capture a provider-aware context without adding their own wrapper
  /// widgets around [child].
  final WidgetBuilder? builder;

  // TODO(any): Remove in 4.0.0
  /// The root widget of the application.
  ///
  /// Deprecated: prefer [builder] to construct your root widget with a
  /// provider-aware BuildContext from inside `ArcaneApp`.
  @Deprecated(
    "Deprecated in 2.0.0. Will be removed in 4.0.0. "
    "Prefer ArcaneApp.builder so your app root is built with Arcane-provided context.",
  )
  final Widget? child;

  // TODO(any): Remove in 4.0.0
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
  /// ArcaneApp(builder: (context) => MyApp())
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// ArcaneApp(
  ///   services: [MyArcaneService()],
  ///   builder: (context) => MyApp(),
  /// );
  /// ```
  const ArcaneApp({
    @Deprecated(
      "Deprecated in 2.0.0. Will be removed in 4.0.0. "
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

  List<ArcaneService> _computeMergedServices() {
    final List<ArcaneService> merged = List<ArcaneService>.from(
      widget.services,
    );
    final Set<Type> existingTypes =
        merged.map((service) => service.runtimeType).toSet();

    // Use Arcane.builtInServices directly to avoid registry recursion during init.
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
    ArcaneServices.I.register(_computeMergedServices());
    ArcaneServiceExtensions.register();
  }

  @override
  void didUpdateWidget(covariant ArcaneApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    final List<ArcaneService> mergedServices = _computeMergedServices();
    if (!_serviceListEquality.equals(
      ArcaneServices.I.services,
      mergedServices,
    )) {
      ArcaneServices.I.register(mergedServices);
    }
  }

  @override
  void dispose() {
    ArcaneServices.I.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneServiceProvider(
      child: ArcaneFeatureFlagsProvider(
        child: ArcaneEnvironmentProvider(
          child: ArcaneThemeSwitcher(
            child:
                // TODO(any): Remove in 4.0.0
                widget.child ??
                Builder(
                  builder: (context) => widget.builder!.call(context),
                ),
          ),
        ),
      ),
    );
  }
}
