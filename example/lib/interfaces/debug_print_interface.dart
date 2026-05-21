import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";

class DebugPrint extends LoggingInterface {
  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level = Level.debug,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    debugPrint("[${level!.name}] $message ($metadata)");
  }
}
