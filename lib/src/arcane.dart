import "package:arcane_auth/arcane_auth.dart";
import "package:arcane_environment/arcane_environment.dart";
import "package:arcane_feature_flags/arcane_feature_flags.dart";
import "package:arcane_logger/arcane_logger.dart";
import "package:arcane_service/arcane_service.dart";
import "package:arcane_theme/arcane_theme.dart";
import "package:flutter/foundation.dart";

export "package:arcane_logger/arcane_logger.dart";
export "package:arcane_service/arcane_service.dart";
export "package:arcane_theme/arcane_theme.dart";

/// A singleton class that acts as the central hub for various services in the
/// Arcane framework.
///
/// `Arcane` provides access to important services like logging, feature flags,
/// authentication, theming, and environment management. The set of available
/// services is held by [ArcaneServices] (the registry/locator); `Arcane` simply
/// exposes convenient typed getters over it.
abstract class Arcane {
  // The built-in singleton services (used as fallback if no app registered
  // services via `ArcaneApp`).
  /// The services that ship with the framework.
  @internal
  static List<ArcaneService> get builtInServices => List.unmodifiable([
    ArcaneFeatureFlagService.I,
    ArcaneAuthenticationService.I,
    ArcaneThemeService.I,
    ArcaneEnvironmentService.I,
  ]);

  /// Provides access to the singleton instance of the logger service.
  ///
  /// The `ArcaneLogger` is used for logging messages throughout the app.
  /// Logger is not a service and is always the singleton.
  static ArcaneLogger get logger => ArcaneLogger.I;

  /// The singleton service registry and locator.
  static ArcaneServices get service => ArcaneServices.I;

  /// Provides access to the feature flags service.
  static ArcaneFeatureFlagService get features => ArcaneFeatureFlagService.I;

  /// Provides access to the authentication service.
  static ArcaneAuthenticationService get auth => ArcaneAuthenticationService.I;

  /// Provides access to the theme management service.
  static ArcaneThemeService get theme => ArcaneThemeService.I;

  /// Provides access to the environment service.
  static ArcaneEnvironmentService get environment => ArcaneEnvironmentService.I;

  /// Returns a list of all services available in the Arcane framework.
  ///
  /// When an app has registered services (via `ArcaneApp`) this reflects that
  /// live registry; otherwise it falls back to the built-in singletons.
  static List<ArcaneService> get services {
    final List<ArcaneService> registered = ArcaneServices.I.services;
    return List.unmodifiable(registered.isEmpty ? builtInServices : registered);
  }

  /// Logs a message using the integrated logger.
  ///
  /// This method is a convenient way to log messages with optional module,
  /// method, log level, stack trace, and additional metadata. The default log
  /// level is `Level.debug`.
  ///
  /// Example:
  /// ```dart
  /// Arcane.log("This is a log message", module: "MyModule", method: "MyMethod");
  /// ```
  ///
  /// - [message]: The message to log.
  /// - [module]: Optional name of the module from which the log originated.
  /// - [method]: Optional name of the method from which the log originated.
  /// - [level]: The log level (e.g., `Level.debug`, `Level.error`), defaults to
  ///    `Level.debug`.
  /// - [stackTrace]: Optional stack trace information.
  /// - [metadata]: Optional additional metadata in key-value pairs
  ///   (`Map<String, Object?>`), which supports structured values such as
  ///   numbers, booleans, nested maps, and lists.
  /// - [extra]: Optional data passed to the logger.
  /// - [skipAutodetection]: Bypass automatically determining the module, method,
  ///   and file/line number of log messages.
  static void log(
    String message, {
    String? module,
    String? method,
    Level level = Level.debug,
    StackTrace? stackTrace,
    Map<String, Object?>? metadata,
    Object? extra,
    bool skipAutodetection = false,
  }) {
    ArcaneLogger.I.log(
      message,
      module: module,
      method: method,
      level: level,
      stackTrace: stackTrace,
      metadata: metadata,
      extra: extra,
      skipAutodetection: skipAutodetection,
    );
  }
}
