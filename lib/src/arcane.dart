import "package:flutter/foundation.dart";

import "service/arcane_service.dart";
import "services/authentication/authentication_service.dart";
import "services/environment/environment_service.dart";
import "services/feature_flags/feature_flags_service.dart";
import "services/logging/logging_service.dart";
import "services/theme/theme_service.dart";

/// A singleton class that acts as the central hub for various services in the
/// Arcane framework.
///
/// `Arcane` provides access to important services like logging, feature flags,
/// authentication, theming, secure storage, and ID management. It also offers a
/// convenient method for logging messages using the integrated logger.
abstract class Arcane {
  // Internal registry for service instances, set by ArcaneApp if present.
  static ValueNotifier<List<ArcaneService>>? registry;

  // Called by ArcaneApp to register the live service registry.
  /// Called by ArcaneApp to register the live service registry.
  static void setRegistry(ValueNotifier<List<ArcaneService>> r) {
    registry = r;
  }

  // Called by ArcaneApp to clear the registry when disposed.
  /// Called by ArcaneApp to clear the registry when disposed.
  static void clearRegistry() {
    registry = null;
  }

  // The built-in singleton services (used as fallback if no ArcaneApp is present).
  static List<ArcaneService> get builtInServices => [
        ArcaneFeatureFlagService.I,
        ArcaneAuthenticationService.I,
        ArcaneThemeService.I,
        ArcaneEnvironmentService.I,
      ];

  /// Provides access to the singleton instance of the logger service.
  ///
  /// The `ArcaneLogger` is used for logging messages throughout the app.
  /// Logger is not a service and is always the singleton.
  static ArcaneLogger get logger => ArcaneLogger.I;

  /// Provides access to the feature flags service instance registered in ArcaneApp, or the singleton if not present.
  static ArcaneFeatureFlagService get features =>
      services.whereType<ArcaneFeatureFlagService>().firstOrNull ??
      ArcaneFeatureFlagService.I;

  /// Provides access to the authentication service instance registered in ArcaneApp, or the singleton if not present.
  static ArcaneAuthenticationService get auth =>
      services.whereType<ArcaneAuthenticationService>().firstOrNull ??
      ArcaneAuthenticationService.I;

  /// Provides access to the theme management service instance registered in ArcaneApp, or the singleton if not present.
  /// Returns ArcaneThemeService, but is also assignable to ArcaneReactiveTheme for backward compatibility.
  static ArcaneThemeService get theme =>
      services.whereType<ArcaneThemeService>().firstOrNull ??
      ArcaneThemeService.I;

  /// Provides access to the environment service instance registered in ArcaneApp, or the singleton if not present.
  static ArcaneEnvironmentService get environment =>
      services.whereType<ArcaneEnvironmentService>().firstOrNull ??
      ArcaneEnvironmentService.I;

  /// Returns a list of all services available in the Arcane framework.
  ///
  /// This list includes the feature flags, authentication, theme, and environment services.
  /// If ArcaneApp is present, this reflects the live registry; otherwise, falls back to built-in singletons.
  static List<ArcaneService> get services => registry?.value ?? builtInServices;

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
  /// - [metadata]: Optional additional metadata in key-value pairs.
  /// - [extra]: Optional data passed to the logger.
  /// - [skipAutodetection]: Bypass automatically determining the module, method,
  ///   and file/line number of log messages.
  static void log(
    String message, {
    String? module,
    String? method,
    Level level = Level.debug,
    StackTrace? stackTrace,
    Map<String, String>? metadata,
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
