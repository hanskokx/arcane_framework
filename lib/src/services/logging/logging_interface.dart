part of "logging_service.dart";

/// Represents a logging interface that can log messages to different destinations.
///
/// Concrete implementations of this class should override the [log] method to provide
/// platform-specific logging behavior.
abstract class LoggingInterface {
  const LoggingInterface();

  /// This method is called by the `ArcaneLogger` when a log message is
  /// received. See `ArcaneLogger.log` for further details on how logging
  /// works and what options are available.
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  });
}

/// Optional lifecycle contract for logging interfaces that require setup.
abstract interface class LoggingInitializable {
  /// Whether this logging destination has completed initialization.
  bool get initialized;

  /// Initializes this logging destination.
  Future<void> init();
}

/// Default initialization behavior for interfaces that opt into lifecycle.
mixin LoggingInitialization implements LoggingInitializable {
  bool _initialized = false;

  @override
  bool get initialized => _initialized;

  @override
  Future<void> init() async {
    _initialized = true;
  }
}

/// Opt-in mixin that exposes a [name] string on a [LoggingInterface].
///
/// Mix this into a concrete logger to declare what [name] should be associated
/// with this logging interface.
///
/// Example:
/// ```dart
/// class MyLogger extends LoggingInterface with LoggerName {
///   @override
///   String get name => 'my-feature';
///
///   @override
///   void log(String message, {...}) {
///     print('[$name] $message');
///   }
/// }
/// ```
mixin LoggerName on LoggingInterface {
  /// The name associated with this logging interface.
  String get name;
}
