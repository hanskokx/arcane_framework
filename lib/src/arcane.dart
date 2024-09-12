import "package:arcane_framework/arcane_framework.dart";

/// A singleton class that acts as the central hub for various services in the
/// Arcane framework.
///
/// `Arcane` provides access to important services like logging, feature flags,
/// authentication, theming, secure storage, and ID management. It also offers a
/// convenient method for logging messages using the integrated logger.
class Arcane {
  Arcane._internal();

  /// Creates a singleton instance of `Arcane`.
  ///
  /// This factory constructor always returns the same instance of `Arcane`.
  factory Arcane() => Arcane._internal();

  /// Provides access to the singleton instance of the logger service.
  ///
  /// The `ArcaneLogger` is used for logging messages throughout the app.
  static ArcaneLogger get logger => ArcaneLogger.I;

  /// Provides access to the singleton instance of the feature flags service.
  ///
  /// `ArcaneFeatureFlags` manages feature toggles, allowing you to enable or
  /// disable features dynamically.
  static ArcaneFeatureFlags get features => ArcaneFeatureFlags.I;

  /// Provides access to the singleton instance of the authentication service.
  ///
  /// `ArcaneAuthenticationService` manages user authentication, login, and
  /// signup processes.
  static ArcaneAuthenticationService get auth => ArcaneAuthenticationService.I;

  /// Provides access to the singleton instance of the theme management service.
  ///
  /// `ArcaneReactiveTheme` allows switching between light and dark themes and
  /// customizing them.
  static ArcaneReactiveTheme get theme => ArcaneReactiveTheme.I;

  /// Returns a list of all services available in the Arcane framework.
  ///
  /// This list includes the feature flags, authentication, theme, and ID services.
  static List<ArcaneService> get services => [
        features,
        auth,
        theme,
      ];

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
