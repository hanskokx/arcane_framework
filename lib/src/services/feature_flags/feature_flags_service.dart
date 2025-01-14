import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";

part "feature_flags_extensions.dart";

/// A singleton class that manages feature flags in the Arcane architecture.
///
/// `ArcaneFeatureFlags` allows features to be dynamically enabled or disabled
/// at runtime. This can be useful for controlling access to experimental or
/// conditional functionality without requiring an application restart.
///
/// Example usage:
/// ```dart
/// ArcaneFeatureFlags.I.enableFeature(MyFeature.example);
/// if (ArcaneFeatureFlags.I.isEnabled(MyFeature.example)) {
///   // Execute feature-specific logic
/// }
/// ```
class ArcaneFeatureFlags extends ArcaneService {
  ArcaneFeatureFlags._internal();

  /// The singleton instance of `ArcaneFeatureFlags`.
  static final ArcaneFeatureFlags _instance = ArcaneFeatureFlags._internal();

  /// Provides access to the singleton instance of `ArcaneFeatureFlags`.
  static ArcaneFeatureFlags get I => _instance;

  /// A list of enabled features.
  ///
  /// Each feature is represented as an `Enum`. The list holds the features that are
  /// currently enabled.
  List<Enum> get enabledFeatures => _enabledFeatures;
  final List<Enum> _enabledFeatures = [];

  final ValueNotifier<List<Enum>> _notifier = ValueNotifier<List<Enum>>([]);

  /// A `ValueNotifier` that notifies listeners when the list of enabled features changes.
  ValueNotifier<List<Enum>> get notifier => _notifier;

  /// Indicates whether the feature flags have been initialized.
  bool _initialized = false;

  /// Returns whether the feature flags have been initialized.
  ///
  /// This getter is `static` and allows checking the initialization status without needing
  /// to access the instance.
  static bool get initialized => I._initialized;

  /// Checks if a specific [feature] is enabled.
  ///
  /// Returns `true` if the [feature] is in the list of enabled features, otherwise returns `false`.
  bool isEnabled(Enum feature) => _enabledFeatures.contains(feature);

  /// Checks if a specific [feature] is disabled.
  ///
  /// Returns `true` if the [feature] is **not** in the list of enabled features.
  bool isDisabled(Enum feature) => !_enabledFeatures.contains(feature);

  /// Enables a specific [feature].
  ///
  /// If the [feature] is already enabled, this method does nothing. If the feature is successfully
  /// enabled, it logs the action (if the logger is initialized) and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// ArcaneFeatureFlags.I.enableFeature(MyFeature.newFeature);
  /// ```
  ArcaneFeatureFlags enableFeature(Enum feature) {
    if (!I._initialized) _init();

    if (_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.add(feature);
    _notifier.value.add(feature);

    if (Arcane.logger.initialized) {
      Arcane.logger.log(
        "Feature enabled: ${feature.name}",
        level: Level.debug,
        metadata: {
          feature.name: "✅",
        },
      );
    }

    notifyListeners();
    return I;
  }

  /// Disables a specific [feature].
  ///
  /// If the [feature] is already disabled, this method does nothing. If the feature is successfully
  /// disabled, it logs the action (if the logger is initialized) and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// ArcaneFeatureFlags.I.disableFeature(MyFeature.oldFeature);
  /// ```
  ArcaneFeatureFlags disableFeature(Enum feature) {
    if (!I._initialized) _init();
    if (!_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.remove(feature);
    _notifier.value.remove(feature);

    if (Arcane.logger.initialized) {
      Arcane.logger.log(
        "Feature disabled: ${feature.name}",
        level: Level.debug,
        metadata: {
          feature.name: "❌",
        },
      );
    }

    notifyListeners();
    return I;
  }

  /// Initializes the feature flags.
  ///
  /// This method clears the list of enabled features and marks the flags as initialized.
  /// It is called automatically when enabling or disabling features if they haven't
  /// already been initialized.
  void _init() {
    _enabledFeatures.clear();
    _notifier.value.clear();

    I._initialized = true;
    notifyListeners();
  }
}
