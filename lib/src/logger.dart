import "dart:io" show Platform;

import "package:app_tracking_transparency/app_tracking_transparency.dart";
import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework/src/config.dart";
import "package:arcane_framework/src/extensions/string.dart";
import "package:collection/collection.dart";
import "package:flutter/foundation.dart";

export "package:logger/logger.dart" show Level;

class ArcaneLogger {
  ArcaneLogger._internal();

  static final ArcaneLogger _instance = ArcaneLogger._internal();
  static ArcaneLogger get I => _instance;

  final List<LoggingInterface> _interfaces = [];
  static List<LoggingInterface> get interfaces => I._interfaces;

  final Map<String, String> _additionalMetadata = {};
  static Map<String, String> get additionalMetadata => I._additionalMetadata;

  bool _initialized = false;
  static bool get initialized => I._initialized;

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  void init() {
    if (_mocked) return;
    if (initialized) return;

    additionalMetadata.clear();

    FlutterError.onError = (errorDetails) {
      I.log(
        "UNHANDLED FLUTTER ERROR",
        level: Level.error,
        module: errorDetails.library,
        stackTrace: errorDetails.stack,
        metadata: {
          "details": errorDetails.exceptionAsString(),
        },
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      I.log(
        "UNHANDLED PLATFORM ERROR",
        level: Level.error,
        stackTrace: stack,
        metadata: {
          "details": error.toString(),
        },
      );
      return true;
    };

    I._initialized = true;

    if (!ArcaneFeatureFlags.initialized) {
      ArcaneFeatureFlags.I.init();
    }
  }

  /// Logs a message with additional contextual information, optionally including
  /// metadata, stack trace, and log level.
  ///
  /// This method provides a structured way to log messages within the application,
  /// including relevant details such as module, method, and metadata. It supports
  /// different log levels and can format output for easier debugging.
  ///
  /// **Parameters:**
  ///
  /// - `message` (String):
  ///   The main log message to be recorded. This is the primary content that
  ///   describes the event or state being logged.
  ///
  /// - `module` (String?, optional):
  ///   The name of the module where the log originates. If not provided, it will
  ///   be inferred from the current stack trace. This helps in categorizing logs
  ///   by different parts of the application.
  ///
  /// - `method` (String?, optional):
  ///   The name of the method where the log originates. If not provided, it will
  ///   be inferred from the current stack trace. This adds context to the log by
  ///   identifying the specific method generating the log.
  ///
  /// - `level` (Level, optional):
  ///   The severity level of the log. Defaults to `Level.debug`. This determines
  ///   the importance of the log and influences how it is handled and displayed.
  ///
  /// - `stackTrace` (StackTrace?, optional):
  ///   The stack trace associated with the log event. Useful for error and
  ///   warning logs to trace the execution path leading to the log event.
  ///
  /// - `metadata` (Map<String, String>?, optional):
  ///   Additional key-value pairs providing extra context for the log. Commonly
  ///   used for custom information that can aid in diagnosing issues or
  ///   understanding the log in context. If not provided, an empty map is used.
  ///
  /// **Details:**
  ///
  /// The `log` method checks whether logging is enabled or mocked via the
  /// `ArcaneFeature.logging` flag. It then constructs a timestamp and extracts
  /// information from the current stack trace to automatically determine the
  /// `module` and `method` if they are not explicitly provided. This process
  /// can sometimes lead to inaccurate results, thus the optional parameters
  /// which have been provided. The metadata map is populated with default
  /// values, including `timestamp`, `module`, `method`, `filenameAndLineNumber`,
  /// `environment`, and `flutterMode`.
  ///
  /// The log message is formatted and sent to registered external logging
  /// interfaces if external logging is enabled. Finally, the message is printed
  /// to the debug console with structured metadata.
  ///
  /// **Usage:**
  ///
  /// ```dart
  /// ArcaneLogger.log(
  ///   "An example log message",
  ///   level: Level.info,
  ///   module: "MainModule",
  ///   method: "initApp",
  ///   metadata: {
  ///     "example": "value",
  ///   },
  /// );
  /// ```
  ///
  /// **Notes:**
  /// - Logging can be disabled globally via the
  ///   `ArcaneFeature.logging.disabled` flag.
  /// - The method automatically detects the environment and other settings
  ///   to enhance the log output based on the current Flutter mode and platform.
  ///
  void log(
    String message, {
    String? module,
    String? method,
    Level level = Level.debug,
    StackTrace? stackTrace,
    Map<String, String>? metadata,
  }) {
    if (I._mocked) return;
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return;

    metadata ??= <String, String>{};

    final String now = DateTime.now().toIso8601String();
    metadata.putIfAbsent("timestamp", () => now);

    try {
      final List<String> parts = StackTrace.current
          .toString()
          .split("\n")[1]
          .split(RegExp("#1"))[1]
          .trimLeft()
          .split(".");

      module ??= parts.first.replaceFirst("new ", "");
      method ??= parts[1].split(" ").first;

      final String line = parts.last.substring(5).replaceAll(")", "");
      final String file = parts[1].split(" ").last.replaceAll("(package:", "");
      final String fileAndLine = "$file:$line";

      metadata.putIfAbsent("module", () => module!);
      metadata.putIfAbsent("method", () => method!);
      metadata.putIfAbsent("filenameAndLineNumber", () => fileAndLine);
    } catch (_) {}

    metadata.addAll(additionalMetadata);

    // Send the logs to the local debug console, if one is registered
    I._interfaces.firstWhereOrNull((i) => i is ArcaneDebugConsole)?.log(
          message,
          level: level,
          metadata: metadata,
          stackTrace: stackTrace,
        );

    // Send logs to registered interface(s)
    if (ArcaneFeature.externalLogging.enabled) {
      for (final LoggingInterface i in I._interfaces) {
        i.log(
          message,
          level: level,
          metadata: metadata,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Registers a [LoggingInterface] with the [ArcaneLogger]. If
  /// [ArcaneFeature.externalLogging] is enabled, the [LoggingInterface] can
  /// then be initialized by calling [ArcaneLogger.initializeInterfaces()]. If
  /// the app tracking permissions has not yet been granted, you must first call
  /// [ArcaneLogger.initalizeAppTracking(context)], which will automatically
  /// call [ArcaneLogger.initializeInterfaces()].
  ///
  /// Once your [LoggingInterface] has been registered and initialized, logs
  /// will automatically be sent to the interface.
  ArcaneLogger registerInterface(LoggingInterface i) {
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return I;

    if (ArcaneFeature.externalLogging.disabled) {
      I.log(
        "External logging is disabled. Ignoring.",
        level: Level.warning,
      );
      return I;
    }

    I._interfaces.add(i);

    return I;
  }

  /// If [Feature.externalLogging] is enabled, this will iterate over all
  /// registered [LoggingInterface]s and run their [init] method.
  Future<ArcaneLogger> initializeInterfaces() async {
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return I;

    if (ArcaneFeature.externalLogging.enabled) {
      for (final LoggingInterface i in I._interfaces) {
        await i.init();
      }
    }

    return I;
  }

  /// If [Feature.externalLogging] is enabled, this will ask the user to approve
  /// app tracking permissions on iOS. (There is no such permission on Android,
  /// so the request will be ignored.)
  ///
  /// If app tracking has been allowed, all registered [LoggingInterface]s will
  /// be initialized.
  Future<void> initalizeAppTracking({
    Future<void>? trackingDialog,
  }) async {
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return;

    if (ArcaneFeature.externalLogging.disabled) {
      I.log(
        "External logging is disabled. Ignoring.",
        level: Level.warning,
      );
      return;
    }

    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.authorized || Platform.isAndroid) {
      await initializeInterfaces();
      return;
    }

    // If the system can show an authorization request dialog
    if (status == TrackingStatus.notDetermined) {
      // Show a custom explainer dialog before the system dialog
      await trackingDialog;
      // Wait for dialog popping animation
      await Future.delayed(const Duration(milliseconds: 200));
      // Request system's tracking authorization dialog
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  ArcaneLogger removePersistentMetadata(String key) {
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return I;

    final bool keyPresent = additionalMetadata.containsKey(key);

    if (keyPresent) {
      additionalMetadata.removeWhere((k, v) => k == key);
    }

    return I;
  }

  ArcaneLogger addPersistentMetadata(String key, String? value) {
    if (!initialized) init();
    if (ArcaneFeature.logging.disabled) return I;

    final bool keyPresent = additionalMetadata.containsKey(key);

    if (keyPresent && value.isNullOrEmpty) {
      additionalMetadata.removeWhere((k, v) => k == key);
      return I;
    }

    if (value == null) return I;

    additionalMetadata.removeWhere((k, v) => k == key);
    additionalMetadata.putIfAbsent(key, () => value);

    return I;
  }

  void clearPersistentMetadata() => additionalMetadata.clear();
}

abstract class LoggingInterface {
  LoggingInterface._internal();

  static late final LoggingInterface _instance;
  static LoggingInterface get I => _instance;

  final bool _initialized = false;
  static bool get initialized => I._initialized;

  /// Initializes the logging interface
  Future<LoggingInterface?> init();

  /// Logs a message to the logging interface
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level,
    StackTrace? stackTrace,
  });
}

/// A logging interface which specifically targets the local debug console.
/// Logging to the [ArcaneDebugConsole] can be enabled and disabled by toggling
/// the [ArcaneFeature.debugConsoleLogging] value within
/// [Arcane.features.enabledFeatures]. All [LoggingInterface] classes must be
/// registered using [Arcane.logger.registerInterface()] before use.
abstract class ArcaneDebugConsole implements LoggingInterface {}
