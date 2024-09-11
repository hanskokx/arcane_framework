import "package:arcane_framework/src/authentication/authentication_service.dart";
import "package:arcane_framework/src/feature_flags/feature_flags_service.dart";
import "package:arcane_framework/src/id/id_service.dart";
import "package:arcane_framework/src/logging/logging_service.dart";
import "package:arcane_framework/src/providers/service_provider.dart";
import "package:arcane_framework/src/secure_storage/secure_storage_service.dart";
import "package:arcane_framework/src/services/theme.dart";

class Arcane {
  Arcane._internal();

  factory Arcane() => Arcane._internal();

  static ArcaneLogger get logger => ArcaneLogger.I;
  static ArcaneFeatureFlags get features => ArcaneFeatureFlags.I;
  static ArcaneAuthenticationService get auth => ArcaneAuthenticationService.I;
  static ArcaneReactiveTheme get theme => ArcaneReactiveTheme.I;
  static ArcaneSecureStorage get storage => ArcaneSecureStorage.I;
  static ArcaneIdService get id => ArcaneIdService.I;

  static List<ArcaneService> get services => [
        features,
        auth,
        theme,
        id,
      ];

  static void log(
    String message, {
    String? module,
    String? method,
    Level level = Level.debug,
    StackTrace? stackTrace,
    Map<String, String>? metadata,
  }) {
    ArcaneLogger.I.log(
      message,
      module: module,
      method: method,
      level: level,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }
}
