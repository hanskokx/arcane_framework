import "package:arcane_framework/src/services/logging/logging_service.dart";

/// A [LoggingInterface] that buffers recent log events for the framework's
/// runtime introspection extension.
///
/// The buffer retains the most recent [maxEntries] events so a client (the
/// MCP server or the DevTools extension) can poll logs over the VM service
/// without the app keeping an active stream subscription. It is attached to
/// [ArcaneLogger] when `ArcaneApp` mounts; internal to the framework and not
/// part of the public API.
class ArcaneLogBuffer implements LoggingInterface {
  /// Creates a buffer holding up to [maxEntries] events.
  ArcaneLogBuffer({this.maxEntries = 500}) : assert(maxEntries > 0);

  /// The maximum number of buffered events; older events are dropped.
  final int maxEntries;

  final List<Map<String, Object?>> _entries = <Map<String, Object?>>[];
  int _nextId = 0;

  /// The number of currently buffered events.
  int get length => _entries.length;

  /// Whether the buffer is empty.
  bool get isEmpty => _entries.isEmpty;

  /// An immutable copy of all buffered events, oldest first.
  List<Map<String, Object?>> get entries =>
      List<Map<String, Object?>>.unmodifiable(_entries);

  /// Removes all buffered events.
  void clear() => _entries.clear();

  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    _entries.add(<String, Object?>{
      "id": _nextId++,
      "timestamp":
          metadata?["timestamp"]?.toString() ??
          DateTime.now().toIso8601String(),
      "level": (level ?? Level.debug).name,
      "module": metadata?["module"],
      "method": metadata?["method"],
      "message": message,
      "metadata": _jsonSafe(metadata ?? const <String, Object?>{}),
      if (stackTrace != null) "stackTrace": stackTrace.toString(),
      if (extra != null) "extra": _jsonSafe(extra),
    });
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Returns up to [limit] buffered events that pass the given filters.
  ///
  /// [module] and [search] match against the stored `module` and `message`
  /// fields. [minimumLevel] retains only events at or above that severity.
  /// Events are returned oldest first; when [limit] excludes events, the most
  /// recent ones are kept.
  List<Map<String, Object?>> snapshot({
    Level minimumLevel = Level.all,
    String module = "",
    String search = "",
    int? limit,
  }) {
    final List<Map<String, Object?>> result =
        _entries
            .where(
              (Map<String, Object?> entry) =>
                  (module.isEmpty || '${entry["module"]}'.contains(module)) &&
                  (search.isEmpty || '${entry["message"]}'.contains(search)) &&
                  _levelOf(entry).value >= minimumLevel.value,
            )
            .toList();
    final int effectiveLimit =
        limit == null || limit < 0 ? result.length : limit;
    if (result.length <= effectiveLimit) {
      return List<Map<String, Object?>>.unmodifiable(result);
    }
    return List<Map<String, Object?>>.unmodifiable(
      result.sublist(result.length - effectiveLimit),
    );
  }

  static Level _levelOf(Map<String, Object?> entry) {
    final String name = '${entry["level"]}';
    for (final Level level in Level.values) {
      if (level.name == name) return level;
    }
    return Level.all;
  }

  static Object? _jsonSafe(Object? value) {
    if (value is String || value is num || value is bool || value == null) {
      return value;
    }
    if (value is Map) {
      return <String, Object?>{
        for (final Object? key in value.keys)
          key.toString(): _jsonSafe(value[key]),
      };
    }
    if (value is Iterable) {
      return <Object?>[for (final Object? item in value) _jsonSafe(item)];
    }
    return value.toString();
  }
}
