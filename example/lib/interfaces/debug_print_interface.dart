import "package:arcane_framework/arcane_framework.dart";
import "package:example/config.dart";
import "package:flutter/foundation.dart";

class DebugPrint implements LoggingInterface {
  DebugPrint._internal();
  static final DebugPrint _instance = DebugPrint._internal();
  static DebugPrint get I => _instance;

  @override
  bool get initialized => true;

  @override
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level = Level.debug,
    StackTrace? stackTrace,
  }) {
    if (Feature.logging.disabled) return;

    debugPrint("[${level!.name}] $message ($metadata)");
  }

  @override
  Future<LoggingInterface?> init() async => I;
}
