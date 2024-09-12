part of "logging_service.dart";

/// Enum representing the different logging levels used to control logging
/// output.
///
/// Each `Level` has an associated integer value that represents its severity.
/// Logging can be filtered to include only messages above a certain `Level`.
///
/// Example usage:
/// ```dart
/// Arcane.log("This is an info message", level: Level.info);
/// ```
///
/// The levels are as follows:
/// - `all`: Logs all messages, regardless of level.
/// - `trace`: Used for very fine-grained debugging information.
/// - `debug`: Used for general debugging information.
/// - `info`: Used for informational messages.
/// - `warning`: Used for warnings that may indicate potential problems.
/// - `error`: Used for errors that prevent the normal flow of execution.
/// - `fatal`: Used for severe errors that may cause the application to crash.
/// - `off`: Disables logging output entirely.
enum Level {
  /// Logs all messages, regardless of severity level.
  all(0),

  /// Logs very fine-grained debugging information.
  trace(1000),

  /// Logs general debugging information.
  debug(2000),

  /// Logs informational messages.
  info(3000),

  /// Logs warning messages that may indicate potential problems.
  warning(4000),

  /// Logs error messages that prevent the normal flow of execution.
  error(5000),

  /// Logs severe errors that may cause the application to crash.
  fatal(6000),

  /// Disables all logging.
  off(10000),
  ;

  /// The integer value representing the severity of the logging level.
  ///
  /// Lower values represent lower severity, while higher values represent
  /// higher severity.
  final int value;

  /// Creates a `Level` with the specified [value].
  const Level(this.value);
}
