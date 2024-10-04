part of "logging_service.dart";

/// Represents a logging interface that can log messages to different destinations.
///
/// Concrete implementations of this class should override the [log] method to provide
/// platform-specific logging behavior.
abstract class LoggingInterface {
  LoggingInterface._internal();
  static late final LoggingInterface _instance;

  /// Provides access to the singleton instance of the `LoggingInterface`. This
  /// ensures that the logging interface, once configured, remains so.
  static LoggingInterface get I => _instance;

  final bool _initialized = false;

  /// Whether the logging interface has been initialized.
  bool get initialized => I._initialized;

  /// Initializes the logging interface.
  ///
  /// If any configuration needs to be performed on the logging interface prior
  /// to use, this is where it should be done.
  /// This method should, at a minimum, set `I._initialized = true`.
  Future<LoggingInterface?> init();

  /// This method is called by the `ArcaneLogger` when a log message is
  /// received. See `ArcaneLogger.log` for further details on how logging
  /// works and what options are available.
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  });
}
