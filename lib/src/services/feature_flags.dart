import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework/src/config.dart";
import "package:arcane_framework/src/services/service_provider.dart";
import "package:flutter/foundation.dart";

class ArcaneFeatureFlags extends ArcaneService {
  ArcaneFeatureFlags._internal();
  static final ArcaneFeatureFlags _instance = ArcaneFeatureFlags._internal();
  static ArcaneFeatureFlags get I => _instance;

  final List<ArcaneFeature> _enabledFeatures = [];

  List<ArcaneFeature> get enabledFeatures => _enabledFeatures;

  bool _initialized = false;
  static bool get initialized => I._initialized;

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  bool isEnabled(ArcaneFeature feature) => _enabledFeatures.contains(feature);

  bool isDisabled(ArcaneFeature feature) => !_enabledFeatures.contains(feature);

  ArcaneFeatureFlags enableFeature(ArcaneFeature feature) {
    if (!initialized) init();
    if (_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.add(feature);

    Arcane.log(
      "Feature enabled",
      level: Level.debug,
      metadata: {
        feature.name:
            ArcaneFeatureFlags.I.isEnabled(feature) == true ? "✅" : "❌",
      },
    );

    notifyListeners();
    return I;
  }

  ArcaneFeatureFlags disableFeature(ArcaneFeature feature) {
    if (!initialized) init();
    if (!_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.remove(feature);

    Arcane.log(
      "Feature disabled",
      level: Level.debug,
      metadata: {
        feature.name:
            ArcaneFeatureFlags.I.isEnabled(feature) == true ? "✅" : "❌",
      },
    );

    notifyListeners();
    return I;
  }

  void init() {
    if (_mocked) return;
    if (initialized) return;

    _enabledFeatures.clear();

    for (final ArcaneFeature feature in ArcaneFeature.values) {
      if (feature.enabledAtStartup) {
        _enabledFeatures.add(feature);
      }
    }

    Arcane.log(
      "Initializing Arcane with features enabled:",
      level: Level.debug,
      metadata: {
        for (final ArcaneFeature feature in ArcaneFeature.values)
          feature.name:
              ArcaneFeatureFlags.I.isEnabled(feature) == true ? "✅" : "❌",
      },
    );

    I._initialized = true;
    notifyListeners();
  }
}

extension FeatureToggles on ArcaneFeature {
  /// Returns [true] if the [Feature] is currently enabled. Otherwise, returns
  /// [false].
  bool get enabled => ArcaneFeatureFlags.I.isEnabled(this);

  /// Returns [false] if the [Feature] is currently enabled. Otherwise, returns
  /// [true].
  bool get disabled => ArcaneFeatureFlags.I.isDisabled(this);

  /// Enables the given [Feature]. Has no effect if the [Feature] is already
  /// enabled.
  void enable() => ArcaneFeatureFlags.I.enableFeature(this);

  /// Disables the given [Feature]. Has no effect if the [Feature] is already
  /// disabled.
  void disable() => ArcaneFeatureFlags.I.disableFeature(this);
}
