part of "logging_service.dart";

/// Provides contextual information for a [LogInterceptor] invocation.
///
/// This context is passed to each log interceptor and can be used to provide
/// additional data or interfaces that may influence how log events are processed.
/// For example, it may contain a reference to the [LoggingInterface] that
/// originated the log event.
///
/// Typically, you do not need to construct this class directly; it is created
/// and managed by the logging framework.
///
/// See also:
/// - [LogInterceptor], which uses this context when intercepting log events.
/// - [LoggingInterface], which may be referenced by this context.

final class LogInterceptorContext {
  /// Creates a new [LogInterceptorContext].
  ///
  /// The [interface] parameter may be used to provide a reference to the
  /// [LoggingInterface] that originated the log event, or may be null if not applicable.
  const LogInterceptorContext({
    this.interface,
  });

  /// The [LoggingInterface] associated with this context, if any.
  ///
  /// This can be used by interceptors to access additional logging features or
  /// metadata about the source of the log event.
  final LoggingInterface? interface;
}

/// A function-like object that intercepts and optionally transforms log events.
///
/// [LogInterceptor] allows you to observe, modify, or suppress log events as
/// they pass through the logging pipeline. You provide a callback that receives
/// each [LogEvent] and its [LogInterceptorContext], and returns either a new
/// (possibly modified) [LogEvent], or `null` to suppress the event.
///
/// Example usage:
/// ```dart
/// final interceptor = LogInterceptor((event, {context}) {
///   // Filter out debug-level logs
///   if (event.level == LogLevel.debug) return null;
///   return event;
/// });
/// ```
///
/// See also:
/// - [LogEvent], which represents a log entry.
/// - [LogInterceptorContext], which provides context for the interception.
class LogInterceptor {
  /// Creates a [LogInterceptor] with the given callback.
  ///
  /// The [_callback] function will be invoked for each log event, with the
  /// event and its context. Return a [LogEvent] to continue processing, or
  /// `null` to suppress the event.
  const LogInterceptor(this._callback);

  /// The callback function that processes each log event.
  ///
  /// The function receives the [event] and its [context], and should return
  /// either a (possibly modified) [LogEvent], or `null` to suppress the event.
  final LogEvent? Function(
    LogEvent event,
    LogInterceptorContext context,
  ) _callback;

  /// Invokes the interceptor on the given [event] and [context].
  ///
  /// Returns the (possibly modified) [LogEvent], or `null` to suppress the event.
  LogEvent? call(
    LogEvent event, {
    required LogInterceptorContext context,
  }) {
    return _callback(event, context);
  }
}
