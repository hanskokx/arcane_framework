import "package:arcane_framework/src/arcane.dart";
import "package:flutter/widgets.dart";

import "feature_flags_provider.dart";

/// Convenience accessors for feature flags from `BuildContext`.
extension ArcaneFeatureFlagsContext on BuildContext {
  /// Returns the nearest [ArcaneFeatureFlagProvider].
  ///
  /// This creates an inherited dependency, so widgets using this getter in
  /// `build` rebuild when enabled features change.
  ArcaneFeatureFlagProvider get featureFlags =>
      ArcaneFeatureFlagProvider.of(this);

  /// Returns the nearest [ArcaneFeatureFlagProvider], if one exists.
  ArcaneFeatureFlagProvider? get maybeFeatureFlags =>
      ArcaneFeatureFlagProvider.maybeOf(this);

  /// Returns `true` when [feature] is enabled.
  ///
  /// If no [ArcaneFeatureFlagProvider] is available in the tree, this falls
  /// back
  /// to [Arcane.features] snapshot state.
  bool isFeatureEnabled(Enum feature) {
    return maybeFeatureFlags?.isEnabled(feature) ??
        Arcane.features.isEnabled(feature);
  }

  /// Returns `true` when [feature] is disabled.
  ///
  /// If no [ArcaneFeatureFlagProvider] is available in the tree, this falls
  /// back
  /// to [Arcane.features] snapshot state.
  bool isFeatureDisabled(Enum feature) {
    return maybeFeatureFlags?.isDisabled(feature) ??
        Arcane.features.isDisabled(feature);
  }
}
