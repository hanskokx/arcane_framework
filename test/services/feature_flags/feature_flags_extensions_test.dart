import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

enum DummyFeature { foo, bar }

void main() {
  setUp(() {
    Arcane.features.disableFeature(DummyFeature.foo);
    Arcane.features.disableFeature(DummyFeature.bar);
  });

  test("enabled/disabled reflect Arcane.features state", () {
    expect(DummyFeature.foo.enabled, isFalse);
    Arcane.features.enableFeature(DummyFeature.foo);
    expect(DummyFeature.foo.enabled, isTrue);
    expect(DummyFeature.foo.disabled, isFalse);
    Arcane.features.disableFeature(DummyFeature.foo);
    expect(DummyFeature.foo.disabled, isTrue);
  });

  test("enable/disable call Arcane.features", () {
    DummyFeature.bar.enable();
    expect(DummyFeature.bar.enabled, isTrue);
    DummyFeature.bar.disable();
    expect(DummyFeature.bar.enabled, isFalse);
  });
}
