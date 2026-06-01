part of "logging_service.dart";

/// Immutable payload representing a single log entry.
///
/// This model is used internally by the logging pipeline and supports
/// JSON round-tripping for persisted or forwarded log events.
class LogEvent {
  static const Object _sentinel = Object();

  const LogEvent({
    required this.message,
    this.metadata,
    this.level,
    this.stackTrace,
    this.extra,
  });

  /// Human-readable log message.
  final String message;

  /// Optional structured context for the log event.
  ///
  /// Values may contain nested maps/lists and are serialized recursively.
  final Map<String, Object?>? metadata;

  /// Optional log level override for this event.
  final Level? level;

  /// Optional captured stack trace associated with the event.
  final StackTrace? stackTrace;

  /// Optional additional payload attached to the event.
  ///
  /// This may be any value and is serialized recursively where possible.
  final Object? extra;

  /// Deserializes a [LogEvent] from a JSON map.
  ///
  /// Nested maps and lists in `metadata` and `extra` are decoded recursively.
  /// `level` is matched by enum name. `stackTrace` is restored as a
  /// string-backed [StackTrace] whose [toString] returns the original text.
  factory LogEvent.fromJson(Map<String, Object?> json) {
    final rawStackTrace = json["stackTrace"];
    final rawLevel = json["level"];

    return LogEvent(
      message: json["message"] as String,
      metadata: json["metadata"].fromJsonMap(),
      level: rawLevel != null
          ? Level.values.firstWhere(
              (l) => l.name == rawLevel,
              orElse: () => Level.debug,
            )
          : null,
      stackTrace: rawStackTrace != null
          ? _StringStackTrace(rawStackTrace as String)
          : null,
      extra: json["extra"].fromJsonValue(),
    );
  }

  /// Serializes this [LogEvent] to a JSON-compatible map.
  ///
  /// `metadata` and `extra` are encoded recursively so nested maps and lists
  /// are preserved. Non-encodable leaf values fall back to [toString].
  /// `level` is stored as its enum name; `stackTrace` as its string form.
  Map<String, Object?> toJson() {
    return {
      "message": message,
      if (metadata != null) "metadata": metadata!.toJsonMap(),
      if (level != null) "level": level!.name,
      if (stackTrace != null) "stackTrace": stackTrace!.toString(),
      if (extra != null) "extra": extra.toJsonValue(),
    };
  }

  /// Returns a copy of this event with selected fields replaced.
  ///
  /// Nullable fields use sentinel values to distinguish "keep existing value"
  /// from "explicitly set to null".
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

/// A [StackTrace] backed by a plain string, used to round-trip stack trace
/// text through JSON without losing the original content.
class _StringStackTrace implements StackTrace {
  const _StringStackTrace(this._trace);

  final String _trace;

  @override
  String toString() => _trace;
}
