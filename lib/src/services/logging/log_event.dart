part of "logging_service.dart";

final class LogEvent {
  static const Object _sentinel = Object();

  const LogEvent({
    required this.message,
    this.metadata,
    this.level,
    this.stackTrace,
    this.extra,
  });

  final String message;
  final Map<String, Object?>? metadata;
  final Level? level;
  final StackTrace? stackTrace;
  final Object? extra;

  LogEvent copyWith({
    String? message,
    Object? metadata = _sentinel,
    Object? level = _sentinel,
    Object? stackTrace = _sentinel,
    Object? extra = _sentinel,
  }) {
    return LogEvent(
      message: message ?? this.message,
      metadata: identical(metadata, _sentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      level: identical(level, _sentinel) ? this.level : level as Level?,
      stackTrace: identical(stackTrace, _sentinel)
          ? this.stackTrace
          : stackTrace as StackTrace?,
      extra: identical(extra, _sentinel) ? this.extra : extra,
    );
  }
}
