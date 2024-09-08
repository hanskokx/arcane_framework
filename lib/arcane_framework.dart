library arcane_framework;

import "package:arcane_framework/src/logger.dart";
import "package:arcane_framework/src/services/feature_flags.dart";

export "package:arcane_framework/src/logger.dart"
    show LoggingInterface, Level, ArcaneLogger, ArcaneDebugConsole;
export "package:arcane_framework/src/services/feature_flags.dart"
    show ArcaneFeatureFlags, FeatureToggles;

class Arcane {
  Arcane._internal();

  factory Arcane() => Arcane._internal();

  static final ArcaneLogger logger = ArcaneLogger.I;
  static final ArcaneFeatureFlags features = ArcaneFeatureFlags.I;

  static void log(
    String message, {
    String? module,
    String? method,
    Level level = Level.debug,
    StackTrace? stackTrace,
    Map<String, String>? metadata,
  }) =>
      logger.log;
}
