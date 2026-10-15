import "package:arcane_feature_flags/arcane_feature_flags.dart";
import "package:test/test.dart";

enum DummyFeature { foo, bar }

void main() {
  setUp(() {
    ArcaneFeatureFlagService.I.disableFeature(DummyFeature.foo);
    ArcaneFeatureFlagService.I.disableFeature(DummyFeature.bar);
  });

  test("enabled/disabled reflect Arcane.features state", () {
    expect(DummyFeature.foo.enabled, isFalse);
    ArcaneFeatureFlagService.I.enableFeature(DummyFeature.foo);
    expect(DummyFeature.foo.enabled, isTrue);
    expect(DummyFeature.foo.disabled, isFalse);
    ArcaneFeatureFlagService.I.disableFeature(DummyFeature.foo);
    expect(DummyFeature.foo.disabled, isTrue);
  });

  test("enable/disable call Arcane.features", () {
    DummyFeature.bar.enable();
    expect(DummyFeature.bar.enabled, isTrue);
    DummyFeature.bar.disable();
    expect(DummyFeature.bar.enabled, isFalse);
  });
}
