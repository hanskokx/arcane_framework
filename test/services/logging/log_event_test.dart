import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("LogEvent", () {
    test("constructor stores provided values", () {
      final event = LogEvent(
        message: "with-data",
        metadata: {
          "flag": true,
          "items": [1, 2, 3],
        },
        level: Level.warning,
        stackTrace: StackTrace.fromString("trace-here"),
        extra: {
          "child": ["x"],
        },
      );

      expect(event.message, "with-data");
      expect(event.metadata?["flag"], isTrue);
      expect(event.metadata?["items"], [1, 2, 3]);
      expect(event.level, Level.warning);
      expect(event.stackTrace.toString(), "trace-here");
      expect(event.extra, {
        "child": ["x"],
      });
    });

    test("constructor leaves optional fields null when omitted", () {
      const event = LogEvent(message: "plain");

      expect(event.message, "plain");
      expect(event.metadata, isNull);
      expect(event.level, isNull);
      expect(event.stackTrace, isNull);
      expect(event.extra, isNull);
    });

    test("copyWith keeps existing values when sentinel defaults are used", () {
      final original = LogEvent(
        message: "original",
        metadata: {"a": 1},
        level: Level.info,
        stackTrace: StackTrace.fromString("trace"),
        extra: "extra",
      );

      final copy = original.copyWith();

      expect(copy.message, "original");
      expect(copy.metadata, original.metadata);
      expect(copy.level, Level.info);
      expect(copy.stackTrace, original.stackTrace);
      expect(copy.extra, "extra");
    });

    test("copyWith supports explicit nulling of nullable fields", () {
      final original = LogEvent(
        message: "original",
        metadata: {"a": 1},
        level: Level.error,
        stackTrace: StackTrace.fromString("trace"),
        extra: 99,
      );

      final cleared = original.copyWith(
        metadata: null,
        level: null,
        stackTrace: null,
        extra: null,
      );

      expect(cleared.message, "original");
      expect(cleared.metadata, isNull);
      expect(cleared.level, isNull);
      expect(cleared.stackTrace, isNull);
      expect(cleared.extra, isNull);
    });
  });
}
