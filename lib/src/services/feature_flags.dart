import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";

class ArcaneFeatureFlags extends ArcaneService {
  ArcaneFeatureFlags._internal();
  static final ArcaneFeatureFlags _instance = ArcaneFeatureFlags._internal();
  static ArcaneFeatureFlags get I => _instance;

  final List<Enum> _enabledFeatures = [];
  List<Enum> get enabledFeatures => _enabledFeatures;

  bool _initialized = false;
  static bool get initialized => I._initialized;

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  bool isEnabled(Enum feature) => _enabledFeatures.contains(feature);
  bool isDisabled(Enum feature) => !_enabledFeatures.contains(feature);

  ArcaneFeatureFlags enableFeature(Enum feature) {
    if (_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.add(feature);

    if (Arcane.logger.initialized) {
      Arcane.logger.log(
        "Feature enabled",
        level: Level.debug,
        metadata: {
          feature.name: feature.enabled ? "✅" : "❌",
        },
      );
    } else {
      debugPrint(
        "Feature enabled: ${feature.name} ${feature.enabled ? "✅" : "❌"}",
      );
    }

    notifyListeners();
    return I;
  }

  ArcaneFeatureFlags disableFeature(Enum feature) {
    if (!_enabledFeatures.contains(feature)) return I;

    _enabledFeatures.remove(feature);

    Arcane.logger.log(
      "Feature disabled",
      level: Level.debug,
      metadata: {
        feature.name: feature.enabled ? "✅" : "❌",
      },
    );

    notifyListeners();
    return I;
  }

  void init() {
    if (_mocked) return;

    _enabledFeatures.clear();

    I._initialized = true;
    notifyListeners();
  }
}

extension FeatureToggles on Enum {
  /// Returns [true] if the [Feature] is currently enabled. Otherwise, returns
  /// [false].
  bool get enabled => Arcane.features.isEnabled(this);

  /// Returns [false] if the [Feature] is currently enabled. Otherwise, returns
  /// [true].
  bool get disabled => Arcane.features.isDisabled(this);

  /// Enables the given [Feature]. Has no effect if the [Feature] is already
  /// enabled.
  void enable() => Arcane.features.enableFeature(this);

  /// Disables the given [Feature]. Has no effect if the [Feature] is already
  /// disabled.
  void disable() => Arcane.features.disableFeature(this);
}
