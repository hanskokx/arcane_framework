import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Environment", () {
    test("built-in values have expected names", () {
      expect(Environment.debug.name, "debug");
      expect(Environment.normal.name, "normal");
    });

    test("isDebug and isNormal reflect built-in values", () {
      expect(Environment.debug.isDebug, isTrue);
      expect(Environment.debug.isNormal, isFalse);

      expect(Environment.normal.isNormal, isTrue);
      expect(Environment.normal.isDebug, isFalse);

      const staging = Environment("staging");
      expect(staging.isDebug, isFalse);
      expect(staging.isNormal, isFalse);
    });

    test("equality and hashCode are name-based", () {
      const first = Environment("staging");
      const second = Environment("staging");
      const prod = Environment("prod");

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(prod));
    });

    test("toString includes environment name", () {
      const staging = Environment("staging");
      expect(staging.toString(), "Environment(staging)");
    });
  });
}
