import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";

part "feature_flags_extensions.dart";

@Deprecated(
  "Deprecated in 2.0.0. "
  "ArcaneFeatureFlags has been renamed to ArcaneFeatureFlagService for clarity. "
  "Please use ArcaneFeatureFlagService instead.",
)
typedef ArcaneFeatureFlags = ArcaneFeatureFlagService;

/// A singleton class that manages feature flags in the Arcane architecture.
///
/// `ArcaneFeatureFlagService` allows features to be dynamically enabled or disabled
/// at runtime. This can be useful for controlling access to experimental or
/// conditional functionality without requiring an application restart.
///
/// Example usage:
/// ```dart
/// ArcaneFeatureFlagService.I.enableFeature(MyFeature.example);
/// if (ArcaneFeatureFlagService.I.isEnabled(MyFeature.example)) {
///   // Execute feature-specific logic
/// }
/// ```
class ArcaneFeatureFlagService extends ArcaneService {
  ArcaneFeatureFlagService._internal();

  /// The singleton instance of `ArcaneFeatureFlagService`.
  static final ArcaneFeatureFlagService _instance =
      ArcaneFeatureFlagService._internal();

  /// Provides access to the singleton instance of `ArcaneFeatureFlagService`.
  static ArcaneFeatureFlagService get I => _instance;

  /// A list of enabled features as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [notifier] (for `ValueListenableBuilder`) or
  /// [enabledFeaturesChanges] (for streams) when you need reactive updates.
  ///
  /// Each feature is represented as an `Enum`. The list holds the features that are
  /// currently enabled.
  List<Enum> get enabledFeatures => _enabledFeatures;
  final List<Enum> _enabledFeatures = [];

  final ValueNotifier<List<Enum>> _notifier = ValueNotifier<List<Enum>>([]);

  /// A `ValueNotifier` that notifies listeners when the list of enabled features changes.
  ValueNotifier<List<Enum>> get notifier => _notifier;

  StreamController<List<Enum>>? _enabledFeaturesStreamController;

  StreamController<List<Enum>> get _enabledFeaturesController {
    _enabledFeaturesStreamController ??=
        StreamController<List<Enum>>.broadcast();
    return _enabledFeaturesStreamController!;
  }

  /// Stream of enabled feature list updates.
  Stream<List<Enum>> get enabledFeaturesChanges =>
      I._enabledFeaturesController.stream;

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
  /// ArcaneFeatureFlagService.I.enableFeature(MyFeature.newFeature);
  /// ```
  ArcaneFeatureFlagService enableFeature(Enum feature) {
    if (!I._initialized) _init();

    if (_enabledFeatures.contains(feature)) return I;

    _notifier.value = [..._enabledFeatures, feature];
    _enabledFeaturesController.add(List<Enum>.from(_notifier.value));

    if (Arcane.logger.initialized) {
      Arcane.logger.log(
        "Feature enabled: $feature",
        level: Level.info,
        metadata: {
          feature.toString(): "✅",
        },
      );
    }

    return I;
  }

  /// Disables a specific [feature].
  ///
  /// If the [feature] is already disabled, this method does nothing. If the feature is successfully
  /// disabled, it logs the action (if the logger is initialized) and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// ArcaneFeatureFlagService.I.disableFeature(MyFeature.oldFeature);
  /// ```
  ArcaneFeatureFlagService disableFeature(Enum feature) {
    if (!I._initialized) _init();
    if (!_enabledFeatures.contains(feature)) return I;

    _notifier.value = [..._enabledFeatures]..removeWhere((i) => i == feature);
    _enabledFeaturesController.add(List<Enum>.from(_notifier.value));

    if (Arcane.logger.initialized) {
      Arcane.logger.log(
        "Feature disabled: $feature",
        level: Level.info,
        metadata: {
          feature.toString(): "❌",
        },
      );
    }

    return I;
  }

  /// Initializes the feature flags.
  ///
  /// This method clears the list of enabled features and marks the flags as initialized.
  /// It is called automatically when enabling or disabling features if they haven't
  /// already been initialized.
  void _init() {
    if (I._initialized) return;
    reset();
    I._initialized = true;
  }

  /// Resets the feature flags to their initial state.
  ///
  /// This method clears all enabled features, resets notification values,
  /// marks the flags as uninitialized, and notifies listeners of the changes.
  void reset() {
    notifier
      ..removeListener(_listener)
      ..addListener(_listener);
    _notifier.value = [];
    _enabledFeaturesController.add(List<Enum>.from(_notifier.value));
    I._initialized = false;
  }

  @override
  void dispose() {
    unawaited(_enabledFeaturesStreamController?.close());
    _enabledFeaturesStreamController = null;
    super.dispose();
  }

  void _listener() {
    _enabledFeatures
      ..clear()
      ..addAll(notifier.value);
  }

  /// Resets the feature flags to their initial state.
  ///
  /// This method clears all enabled features, resets notification values,
  /// marks the flags as uninitialized, and notifies listeners of the changes.
  void reset() {
    _enabledFeatures.clear();
    _notifier.value.clear();

    I._initialized = false;
    notifyListeners();
  }
}
