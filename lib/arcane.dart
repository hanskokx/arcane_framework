import "package:arcane_framework/arcane_framework.dart";

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
