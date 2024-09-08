import "package:flutter/foundation.dart";

enum ArcaneFeature {
  /// Enables the [ArcaneLogger] feature.
  logging(true),

  /// Enables debug logging to print to the local debug console
  debugConsoleLogging(kDebugMode),

  /// Enables logging to external services. Requires [ArcaneFeature.logging] to
  /// also be enabled.
  externalLogging(true),
  ;

  /// Determines whether the given [ArcaneFeatureFeature] is enabled by default.
  final bool enabledAtStartup;

  const ArcaneFeature(this.enabledAtStartup);
}
