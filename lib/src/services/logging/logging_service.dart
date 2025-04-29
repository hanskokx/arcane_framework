import "dart:async";

import "package:arcane_helper_utils/arcane_helper_utils.dart";

part "logging_enums.dart";
part "logging_interface.dart";

/// A singleton class that manages logging to one or more logging interfaces
/// with optional metadata.
///
/// The `ArcaneLogger` provides a centralized way to log messages across
/// different parts of an application. It supports multiple logging interfaces,
/// metadata, and platform-specific error handling.
class ArcaneLogger {
  ArcaneLogger._internal();

  static final ArcaneLogger _instance = ArcaneLogger._internal();

  /// Provides access to the singleton instance of `ArcaneLogger`.
  static ArcaneLogger get I => _instance;

  final List<LoggingInterface> _interfaces = [];

  /// A list of registered logging interfaces.
  List<LoggingInterface> get interfaces => I._interfaces;

  final Map<String, String> _additionalMetadata = {};

  /// Additional metadata that is included in all logs.
  Map<String, String> get additionalMetadata => I._additionalMetadata;

  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast(
    onCancel: () {
      I._logStreamController.close();
    },
  );

  /// Stream of log messages being received and sent to the registered interfaces.
  Stream<String> get logStream => I._logStreamController.stream;

  bool _initialized = false;

  /// Whether the logger has been initialized.
  bool get initialized => I._initialized;

  /// Initializes the logger.
  ///
  /// Sets up error handling for both Flutter and platform-specific errors.
  /// Also, retrieves the tracking authorization status if running on iOS or
  /// macOS.
  Future<void> _init() async {
    additionalMetadata.clear();

    I._initialized = true;
  }

  /// Logs a message with additional contextual information, optionally including
  /// metadata, stack trace, and log level.
  ///
  /// This method provides a structured way to log messages within an application,
  /// including relevant details such as module, method, and metadata. It supports
  /// different log levels.
  ///
  /// **Parameters:**
  ///
  /// - `message` ([String]):
  ///   The main log message to be recorded. This is the primary content that
  ///   describes the event or state being logged.
  ///
  /// - `module` ([String?], _optional_):
  ///   The name of the module where the log originates. If not provided, it will
  ///   be inferred from the current stack trace. This helps in categorizing logs
  ///   by different parts of the application.
  ///
  /// - `method` ([String?], _optional_):
  ///   The name of the method where the log originates. If not provided, it will
  ///   be inferred from the current stack trace. This adds context to the log by
  ///   identifying the specific method generating the log.
  ///
  /// - `level` ([Level], _optional_):
  ///   The severity level of the log. Defaults to `Level.debug`. This determines
  ///   the importance of the log and influences how it is handled and displayed.
  ///
  /// - `stackTrace` ([StackTrace?], _optional_):
  ///   The stack trace associated with the log event. Useful for error and
  ///   warning logs to trace the execution path leading to the log event.
  ///
  /// - `metadata` ([Map<String, String>?], _optional_):
  ///   Additional key-value pairs providing extra context for the log. Commonly
  ///   used for custom information that can aid in diagnosing issues or
  ///   understanding the log in context. If not provided, an empty map is used.
  ///
  /// - `extra` ([Object?], _optional_):
  ///   Allows for passing additional, arbitrary objects of any type into the
  ///   logging interface. This is a general-purpose object that could be used
  ///   for anything from passing an [Exception] for additional processing, to
  ///   any other purpose one could dream up.
  ///
  /// **Details:**
  ///
  /// The `log` method constructs a timestamp and extracts information from the
  /// current stack trace to automatically determine the `module` and `method`
  /// if they are not explicitly provided. This process can sometimes lead to\
  /// inaccurate results, thus the optional parameters which have been provided.
  /// The metadata map is populated with default values, including `timestamp`,
  /// `module`, `method`, and `filenameAndLineNumber`.
  ///
  /// The log message and associated metadata is sent to any and all registered
  /// logging interfaces.
  ///
  /// **Usage:**
  ///
  /// ```dart
  /// ArcaneLogger.log(
  ///   "An example log message",
  ///   level: Level.info,
  ///   module: "MyStateManagement",
  ///   method: "onProcessEvent",
  ///   metadata: {
  ///     "example": "value",
  ///   },
  /// );
  /// ```
  ///
  void log(
    /// The message to be logged
    String message, {
    /// The Dart class from which the `log` call was invoked. This is useful
    /// in determining which part of the code called the log event. If the
    /// [module] is not specified and [skipAutodetection] is set to [false],
    /// [ArcaneLogger] will attempt to derive this value automatically. However,
    /// this may fail in some cases and could potentially adversely impact
    /// performance.
    String? module,

    /// The method from which the `log` call was invoked. This is useful
    /// in determining which part of the code called the log event. If the
    /// [method] is not specified and [skipAutodetection] is set to [false],
    /// [ArcaneLogger] will attempt to derive this value automatically. However,
    /// this may fail in some cases and could potentially adversely impact
    /// performance.
    String? method,

    /// This value defines the severity of the log message. The default value is
    /// [Level.debug].
    Level level = Level.debug,

    /// A [StackTrace] can be passed into the `log` call for further processing
    /// by the registered [LoggingInterface]s.
    StackTrace? stackTrace,

    /// The provided [metadata] will be merged with any previously registered
    /// persistent metadata. If the [module] and/or [method] are provided, these
    /// values will be merged with the [metadata] as well, otherwise if one or
    /// none of these values are provided and [skipAutodetection] is set to
    /// [false] (default), the module, method, and/or [filenameAndLineNumber]
    /// will be automatically determined and added to the [metadata] if the
    /// values are not already present.
    Map<String, String>? metadata,

    /// The [extra] parameter can be used to pass _any_ object into the
    /// registered [LoggingInterface]s.
    Object? extra,

    /// If set to [true], this parameter will skip automatically trying to
    /// determine the current log message's [module], [method], and
    /// [filenameAndLineNumber].
    ///
    /// If set to [true] and the [filenameAndLineNumber] are desired, they
    /// should be calculated by the [LoggingInterface] and added as as
    /// [metadata].
    ///
    /// If this value is [false] (default), the [module] and [method] will only
    /// be added to the [metadata] if they are not otherwise provided. However,
    /// the [filenameAndLineNumber] will automatically be added _unless_ it is
    /// already in the [metadata] provided.
    ///
    /// When set to [true], the automatic generation of these values _may_
    /// impact performance.
    bool skipAutodetection = false,
  }) {
    metadata ??= <String, String>{};
    metadata.putIfAbsent("timestamp", () => DateTime.now().toIso8601String());

    String? filenameAndLineNumber;
    if (!skipAutodetection) {
      String? parts;
      try {
        parts = StackTrace.current
            .toString()
            .split("\n")[2]
            .split(RegExp("#2"))[1]
            .trim();
      } catch (_) {}

      module ??= parts?.split(".").firstOrNull?.replaceFirst("new ", "");

      method ??= ((parts?.split(".").length ?? 0) <= 1)
          ? null
          : parts
              ?.split(".")[1]
              .split(" ")
              .firstOrNull
              ?.replaceAll("<anonymous", "");

      final List<String> fileAndLineParts = [
        ...?parts?.split("(package:").lastOrNull?.split(":"),
      ];

      if (fileAndLineParts.length < 2) {
        filenameAndLineNumber = fileAndLineParts.firstOrNull;
      } else {
        filenameAndLineNumber = "${fileAndLineParts[0]}:${fileAndLineParts[1]}";
      }
    }

    // Module management
    if (module.isNotEmptyOrNull) {
      metadata.putIfAbsent("module", () => module!);
    }

    // Method managmeent
    if (method.isNotEmptyOrNull) {
      metadata.putIfAbsent("method", () => method!);
    }

    // Filename and line number management
    if (filenameAndLineNumber.isNotNullOrEmpty) {
      metadata.putIfAbsent(
        "filenameAndLineNumber",
        () => filenameAndLineNumber!,
      );
    }

    metadata.addAll(additionalMetadata);

    module ??= metadata.containsKey("module") ? metadata["module"] : null;
    method ??= metadata.containsKey("method") ? metadata["method"] : null;

    // Send logs to registered interface(s)
    for (final LoggingInterface i in I._interfaces) {
      i.log(
        message,
        level: level,
        metadata: metadata,
        stackTrace: stackTrace,
        extra: extra,
      );
    }

    _logStreamController.add(
      "$message ${{
        "level": level,
        "metadata": metadata,
        "extra": extra,
      }}",
    );
  }

  /// Registers a [LoggingInterface] with the [ArcaneLogger].
  /// Due to iOS app tracking permissions, permission to track must first be
  /// checked for and (optionally) granted before the interface is automatically
  /// initialized.
  ///
  /// Once your [LoggingInterface] has been registered and initialized, logs
  /// will automatically be sent to the interface.
  Future<ArcaneLogger> registerInterface(
    LoggingInterface loggingInterface,
  ) async {
    if (!initialized) await _init();

    I._interfaces.add(loggingInterface);

    return I;
  }

  /// Registers a `List` of [LoggingInterface] with the [ArcaneLogger].
  /// Due to iOS app tracking permissions, permission to track must first be
  /// checked for and (optionally) granted before the interface is automatically
  /// initialized.
  ///
  /// Once your [LoggingInterface] has been registered and initialized, logs
  /// will automatically be sent to the interface.
  Future<ArcaneLogger> registerInterfaces(
    List<LoggingInterface> interfaces,
  ) async {
    if (!initialized) await _init();

    for (final LoggingInterface i in interfaces) {
      I._interfaces.add(i);
    }

    return I;
  }

  /// Unregisters a [LoggingInterface] from the [ArcaneLogger], if it was
  /// previously registered.
  Future<ArcaneLogger> unregisterInterface(
    LoggingInterface interface,
  ) async {
    if (!initialized) await _init();

    I._interfaces.remove(interface);

    return I;
  }

  /// Unregisters a `List` of [LoggingInterface] from the [ArcaneLogger], if
  /// they were previously registered.
  Future<ArcaneLogger> unregisterInterfaces(
    List<LoggingInterface> interfaces,
  ) async {
    if (!initialized) await _init();

    for (final LoggingInterface i in interfaces) {
      I._interfaces.remove(i);
    }

    return I;
  }

  /// Unregisters all previously registered [LoggingInterface] from the
  /// [ArcaneLogger], if any were previously registered.
  Future<ArcaneLogger> unregisterAllInterfaces() async {
    if (!initialized) await _init();
    I._interfaces.clear();
    return I;
  }

  /// Initializes all registered [LoggingInterface]s by calling their
  /// [LoggingInterface.init] methods.
  Future<ArcaneLogger> initializeInterfaces() async {
    if (!initialized) await _init();

    if (I._interfaces.isEmptyOrNull) {
      throw Exception("No logging interfaces have been registered.");
    }

    for (final LoggingInterface i in I._interfaces) {
      if (!i.initialized) await i.init();
    }

    return I;
  }

  /// Removes a specific key from the persistent metadata.
  ArcaneLogger removePersistentMetadata(String key) {
    final bool keyPresent = additionalMetadata.containsKey(key);

    if (keyPresent) {
      additionalMetadata.removeWhere((k, v) => k == key);
    }

    return I;
  }

  /// Adds or updates persistent metadata.
  ///
  /// This metadata will be included in all future log messages.
  ArcaneLogger addPersistentMetadata(Map<String, String?> input) {
    for (final entry in input.entries) {
      final String key = entry.key;
      final String? value = entry.value;

      final bool keyPresent = _additionalMetadata.containsKey(key);

      if (keyPresent && value.isNullOrEmpty) {
        _additionalMetadata.removeWhere((k, v) => k == key);
        return I;
      }

      if (value == null) return I;

      _additionalMetadata.removeWhere((k, v) => k == key);
      _additionalMetadata.putIfAbsent(key, () => value);
    }

    return I;
  }

  /// Clears all persistent metadata.
  void clearPersistentMetadata() => _additionalMetadata.clear();

  /// Resets the Arcane logging service by clearing all persistent metadata,
  /// clearing all registered [LoggingInterface]s and marking the logging
  /// service as no longer being initialized.
  void reset() {
    I._interfaces.clear();
    I._initialized = false;
    I._additionalMetadata.clear();
  }
}
