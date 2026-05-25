import "package:arcane_framework/src/arcane.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

/// An `InheritedWidget` that provides access to enabled feature flags.
///
/// Descendant widgets that call [of] or [maybeOf] will rebuild when the
/// enabled feature set changes.
class ArcaneFeatureFlagProvider extends InheritedWidget {
  /// The currently enabled feature flags.
  final List<Enum> enabledFeatures;

  final ValueChanged<Enum> _enableFeature;
  final ValueChanged<Enum> _disableFeature;

  /// Creates an `ArcaneFeatureFlagProvider` widget.
  const ArcaneFeatureFlagProvider({
    required this.enabledFeatures,
    required void Function(Enum) enableFeature,
    required void Function(Enum) disableFeature,
    required super.child,
    super.key,
  })  : _enableFeature = enableFeature,
        _disableFeature = disableFeature;

  /// Retrieves the nearest `ArcaneFeatureFlagProvider` from the widget tree.
  ///
  /// Returns `null` if no `ArcaneFeatureFlagProvider` ancestor is found.
  static ArcaneFeatureFlagProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ArcaneFeatureFlagProvider>();
  }

  /// Retrieves the nearest `ArcaneFeatureFlagProvider` from the widget tree.
  ///
  /// Throws a `StateError` if no `ArcaneFeatureFlagProvider` ancestor is found.
  static ArcaneFeatureFlagProvider of(BuildContext context) {
    final ArcaneFeatureFlagProvider? result = maybeOf(context);
    if (result == null) {
      throw StateError("No ArcaneFeatureFlagProvider found in context");
    }
    return result;
  }

  /// Returns whether [feature] is currently enabled.
  bool isEnabled(Enum feature) => enabledFeatures.contains(feature);

  /// Returns whether [feature] is currently disabled.
  bool isDisabled(Enum feature) => !isEnabled(feature);

  /// Enables [feature].
  void enableFeature(Enum feature) => _enableFeature(feature);

  /// Disables [feature].
  void disableFeature(Enum feature) => _disableFeature(feature);

  /// A `ValueListenable` that can be used for reactive feature flag updates.
  ValueListenable<List<Enum>> get notifier => Arcane.features.notifier;

  /// A stream of enabled feature flag updates.
  Stream<List<Enum>> get enabledFeaturesChanges =>
      Arcane.features.enabledFeaturesChanges;

  @override
  bool updateShouldNotify(ArcaneFeatureFlagProvider oldWidget) {
    return !listEquals(enabledFeatures, oldWidget.enabledFeatures);
  }
}

@Deprecated(
  "Deprecated in 2.0.0. "
  "ArcaneFeatureFlagsScope has been renamed to ArcaneFeatureFlagProvider. "
  "Please use ArcaneFeatureFlagProvider instead.",
)
typedef ArcaneFeatureFlagsScope = ArcaneFeatureFlagProvider;

/// A `StatefulWidget` that keeps [ArcaneFeatureFlagProvider] in sync with
/// [ArcaneFeatureFlagService] and rebuilds descendants when flags change.
class ArcaneFeatureFlagsProvider extends StatefulWidget {
  /// The child widget that will have access to feature flags.
  final Widget child;

  /// Creates an `ArcaneFeatureFlagsProvider`.
  const ArcaneFeatureFlagsProvider({
    required this.child,
    super.key,
  });

  @override
  State<ArcaneFeatureFlagsProvider> createState() =>
      _ArcaneFeatureFlagsProviderState();
}

class _ArcaneFeatureFlagsProviderState
    extends State<ArcaneFeatureFlagsProvider> {
  late List<Enum> _enabledFeatures;

  void _handleFeatureFlagsChange() {
    if (!mounted) return;

    final List<Enum> nextEnabled =
        List<Enum>.from(Arcane.features.notifier.value);
    if (listEquals(nextEnabled, _enabledFeatures)) return;

    setState(() {
      _enabledFeatures = nextEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    _enabledFeatures = List<Enum>.from(Arcane.features.notifier.value);
    Arcane.features.notifier.addListener(_handleFeatureFlagsChange);
  }

  @override
  void dispose() {
    Arcane.features.notifier.removeListener(_handleFeatureFlagsChange);
    super.dispose();
  }

  void enableFeature(Enum feature) {
    Arcane.features.enableFeature(feature);
  }

  void disableFeature(Enum feature) {
    Arcane.features.disableFeature(feature);
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneFeatureFlagProvider(
      enabledFeatures: List<Enum>.unmodifiable(_enabledFeatures),
      enableFeature: enableFeature,
      disableFeature: disableFeature,
      child: widget.child,
    );
  }
}
