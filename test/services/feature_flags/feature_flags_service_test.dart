import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneFeatureFlags", () {
    late ArcaneFeatureFlags featureFlags;

    setUp(() {
      featureFlags = ArcaneFeatureFlags.I;
      Arcane.features.reset();
    });

    test("singleton instance is consistent", () {
      expect(identical(ArcaneFeatureFlags.I, featureFlags), true);
    });

    group("feature management", () {
      test("enableFeature adds feature to enabled list", () {
        featureFlags.enableFeature(MockFeature.test);
        expect(featureFlags.enabledFeatures, contains(MockFeature.test));
        expect(featureFlags.isEnabled(MockFeature.test), true);
      });

      test("disableFeature removes feature from enabled list", () {
        featureFlags.enableFeature(MockFeature.test);
        featureFlags.disableFeature(MockFeature.test);
        expect(featureFlags.enabledFeatures, isNot(contains(MockFeature.test)));
        expect(featureFlags.isDisabled(MockFeature.test), true);
      });

      test("enabling already enabled feature has no effect", () {
        featureFlags.enableFeature(MockFeature.test);
        final initialCount = featureFlags.enabledFeatures.length;
        featureFlags.enableFeature(MockFeature.test);
        expect(featureFlags.enabledFeatures.length, equals(initialCount));
      });

      test("disabling already disabled feature has no effect", () {
        final initialCount = featureFlags.enabledFeatures.length;
        featureFlags.disableFeature(MockFeature.test);
        expect(featureFlags.enabledFeatures.length, equals(initialCount));
      });
    });

    group("notifications", () {
      test("enableFeature notifies listeners", () {
        var notified = false;
        featureFlags.notifier.addListener(() => notified = true);
        featureFlags.enableFeature(MockFeature.test);
        expect(notified, true);
      });

      test("disableFeature notifies listeners", () {
        featureFlags.enableFeature(MockFeature.test);
        var notified = false;
        featureFlags.notifier.addListener(() => notified = true);
        featureFlags.disableFeature(MockFeature.test);
        expect(notified, true);
      });

      test("enabledFeaturesChanges emits updates", () async {
        List<Enum>? emitted;
        final subscription =
            featureFlags.enabledFeaturesChanges.listen((features) {
          emitted = features;
        });

        featureFlags.enableFeature(MockFeature.test);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, contains(MockFeature.test));

        await subscription.cancel();
      });

      test("enabledFeaturesChanges works after listener cancellation",
          () async {
        List<Enum>? firstEmission;
        final firstSubscription =
            featureFlags.enabledFeaturesChanges.listen((features) {
          firstEmission = features;
        });

        featureFlags.enableFeature(MockFeature.test);
        await Future<void>.delayed(Duration.zero);
        expect(firstEmission, contains(MockFeature.test));

        await firstSubscription.cancel();

        List<Enum>? secondEmission;
        final secondSubscription =
            featureFlags.enabledFeaturesChanges.listen((features) {
          secondEmission = features;
        });

        featureFlags.disableFeature(MockFeature.test);
        await Future<void>.delayed(Duration.zero);
        expect(secondEmission, isNot(contains(MockFeature.test)));

        await secondSubscription.cancel();
      });
    });
  });
}

enum MockFeature {
  test,
  another,
}
