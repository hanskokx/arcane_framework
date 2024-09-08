import "package:arcane_framework/src/logger.dart";
import "package:arcane_framework/src/services/authentication.dart";
import "package:arcane_framework/src/services/feature_flags.dart";
import "package:arcane_framework/src/services/theme.dart";

class Arcane {
  Arcane._internal();

  factory Arcane() => Arcane._internal();

  static final ArcaneLogger logger = ArcaneLogger.I;
  static final ArcaneFeatureFlags features = ArcaneFeatureFlags.I;
  static final ArcaneAuthenticationService auth = ArcaneAuthenticationService.I;
  static final ArcaneReactiveTheme theme = ArcaneReactiveTheme.I;

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
