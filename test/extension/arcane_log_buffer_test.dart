import "dart:convert";

import "package:arcane_framework/src/extension/arcane_log_buffer.dart";
import "package:arcane_framework/src/services/logging/logging_service.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("ArcaneLogBuffer", () {
    test("buffers log events with sane defaults", () {
      final ArcaneLogBuffer buffer = ArcaneLogBuffer();
      buffer.log(
        "hello",
        level: Level.info,
        metadata: const <String, Object?>{"module": "example"},
      );

      expect(buffer.length, 1);
      expect(buffer.isEmpty, isFalse);

      final Map<String, Object?> entry = buffer.entries.single;
      expect(entry["message"], "hello");
      expect(entry["level"], "info");
      expect(entry["module"], "example");
      expect(entry["id"], 0);
    });

    test("keeps metadata JSON-encodable", () {
      final ArcaneLogBuffer buffer = ArcaneLogBuffer();
      buffer.log(
        "with objects",
        metadata: <String, Object?>{
          "map": const <String, Object?>{"a": 1},
          "list": const <Object?>[1, 2],
          "stamp": DateTime.utc(2025),
        },
        extra: const <String, Object?>{
          "trace": <Object?>["a", "b"],
        },
      );

      final Map<String, Object?> entry = buffer.entries.single;
      jsonEncode(buffer.entries);
      expect(
        (entry["metadata"]! as Map<String, Object?>)["stamp"],
        isNot(DateTime),
      );
      expect((entry["extra"]! as Map<String, Object?>).isEmpty, isFalse);
    });

    test("trims to maxEntries keeping the newest events", () {
      final ArcaneLogBuffer buffer = ArcaneLogBuffer(maxEntries: 3);
      for (int i = 0; i < 5; i++) {
        buffer.log("message $i", level: Level.debug);
      }

      expect(buffer.length, 3);
      expect(buffer.entries.first["message"], "message 2");
      expect(buffer.entries.last["message"], "message 4");
      expect(buffer.entries.last["id"], 4);
    });

    test("snapshot filters by level, module, search, and limit", () {
      final ArcaneLogBuffer buffer = ArcaneLogBuffer();
      buffer.log(
        "boot failed",
        level: Level.error,
        metadata: const <String, Object?>{"module": "auth"},
      );
      buffer.log(
        "boot done",
        level: Level.info,
        metadata: const <String, Object?>{"module": "app"},
      );
      buffer.log(
        "trace line",
        level: Level.trace,
        metadata: const <String, Object?>{"module": "app"},
      );

      expect(buffer.snapshot(minimumLevel: Level.warning).length, 1);
      expect(buffer.snapshot(module: "app").length, 2);
      expect(buffer.snapshot(search: "boot").length, 2);
      expect(buffer.snapshot(limit: 1).length, 1);
      expect(buffer.snapshot(limit: 1).single["message"], "trace line");
    });

    test("clear empties the buffer", () {
      final ArcaneLogBuffer buffer = ArcaneLogBuffer();
      buffer.log("one", level: Level.debug);
      buffer.clear();
      expect(buffer.isEmpty, isTrue);
    });
  });
}
