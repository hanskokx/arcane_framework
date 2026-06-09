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

  group("LogEvent.fromJson", () {
    test("round-trips a fully populated event", () {
      const original = LogEvent(
        message: "hello",
        metadata: {"key": "value"},
        level: Level.warning,
        extra: 42,
      );

      final json = original.toJson();
      final restored = LogEvent.fromJson(json);

      expect(restored.message, "hello");
      expect(restored.metadata, {"key": "value"});
      expect(restored.level, Level.warning);
      expect(restored.extra, 42);
    });

    test("round-trips an event with a stack trace", () {
      final original = LogEvent(
        message: "crash",
        stackTrace: StackTrace.fromString("frame #0"),
      );

      final json = original.toJson();
      final restored = LogEvent.fromJson(json);

      expect(restored.stackTrace.toString(), "frame #0");
    });

    test("omits null optional fields from toJson output", () {
      const event = LogEvent(message: "bare");
      final json = event.toJson();

      expect(json.containsKey("metadata"), isFalse);
      expect(json.containsKey("level"), isFalse);
      expect(json.containsKey("stackTrace"), isFalse);
      expect(json.containsKey("extra"), isFalse);
    });

    test("fromJson handles missing optional fields gracefully", () {
      final event = LogEvent.fromJson({"message": "minimal"});

      expect(event.message, "minimal");
      expect(event.metadata, isNull);
      expect(event.level, isNull);
      expect(event.stackTrace, isNull);
      expect(event.extra, isNull);
    });

    test("fromJson falls back to Level.debug for unrecognised level name", () {
      final event = LogEvent.fromJson({
        "message": "x",
        "level": "nonExistentLevel",
      });

      expect(event.level, Level.debug);
    });

    test("toJson encodes metadata and extra recursively", () {
      const event = LogEvent(
        message: "nested",
        metadata: {
          "map": {"inner": 1},
          "list": [1, 2, 3],
        },
        extra: {"deep": true},
      );

      final json = event.toJson();
      expect((json["metadata"] as Map)["map"], {"inner": 1});
      expect((json["metadata"] as Map)["list"], [1, 2, 3]);
      expect(json["extra"], {"deep": true});
    });
  });
}
