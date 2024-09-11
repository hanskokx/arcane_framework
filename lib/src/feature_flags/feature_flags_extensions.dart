part of "feature_flags_service.dart";

/// An extension on `Enum` to manage feature toggles.
///
/// This extension provides a convenient way to enable, disable, and check the status
/// of feature flags associated with enum values. It interacts with the `ArcaneFeatureFlags`
/// system to manage these feature flags at runtime.
extension FeatureToggles on Enum {
  /// Returns `true` if the feature represented by this enum is currently enabled.
  ///
  /// Example:
  /// ```dart
  /// if (MyFeature.exampleFeature.enabled) {
  ///   // Feature-specific logic
  /// }
  /// ```
  bool get enabled => Arcane.features.isEnabled(this);

  /// Returns `false` if the feature represented by this enum is currently enabled.
  ///
  /// This is a convenience getter that is the inverse of `enabled`.
  ///
  /// Example:
  /// ```dart
  /// if (MyFeature.exampleFeature.disabled) {
  ///   // Logic for when the feature is disabled
  /// }
  /// ```
  bool get disabled => Arcane.features.isDisabled(this);

  /// Enables the feature represented by this enum.
  ///
  /// If the feature is already enabled, this method has no effect. It interacts with
  /// the `ArcaneFeatureFlags` system to enable the feature.
  ///
  /// Example:
  /// ```dart
  /// MyFeature.exampleFeature.enable();
  /// ```
  void enable() => Arcane.features.enableFeature(this);

  /// Disables the feature represented by this enum.
  ///
  /// If the feature is already disabled, this method has no effect. It interacts with
  /// the `ArcaneFeatureFlags` system to disable the feature.
  ///
  /// Example:
  /// ```dart
  /// MyFeature.exampleFeature.disable();
  /// ```
  void disable() => Arcane.features.disableFeature(this);
}
