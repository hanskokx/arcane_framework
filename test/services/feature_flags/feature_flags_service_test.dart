import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

class FeatureFlagLoggingInterface extends LoggingInterface {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    events.add(
      LogEvent(
        message: message,
        metadata: metadata == null ? null : Map<String, Object?>.from(metadata),
        level: level,
        stackTrace: stackTrace,
        extra: extra,
      ),
    );
  }
}

void main() {
  group("ArcaneFeatureFlagService", () {
    late ArcaneFeatureFlagService featureFlags;

    setUp(() {
      featureFlags = ArcaneFeatureFlagService.I;
      Arcane.features.reset();
      Arcane.logger.reset();
    });

    test("singleton instance is consistent", () {
      expect(identical(ArcaneFeatureFlagService.I, featureFlags), true);
    });

    test("initialized reflects init and reset transitions", () {
      expect(ArcaneFeatureFlagService.initialized, isFalse);
      featureFlags.enableFeature(MockFeature.test);
      expect(ArcaneFeatureFlagService.initialized, isTrue);
      featureFlags.reset();
      expect(ArcaneFeatureFlagService.initialized, isFalse);
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

      test("enableFeature logs when logger is initialized", () async {
        final logger = FeatureFlagLoggingInterface();
        await Arcane.logger.registerInterface(logger);

        featureFlags.enableFeature(MockFeature.test);

        expect(logger.events, isNotEmpty);
        expect(logger.events.last.message, contains("Feature enabled"));
        expect(logger.events.last.level, Level.info);
        expect(
          logger.events.last.metadata?[MockFeature.test.toString()],
          "✅",
        );
      });

      test("disableFeature logs when logger is initialized", () async {
        final logger = FeatureFlagLoggingInterface();
        await Arcane.logger.registerInterface(logger);

        featureFlags.enableFeature(MockFeature.test);
        featureFlags.disableFeature(MockFeature.test);

        expect(logger.events, isNotEmpty);
        expect(logger.events.last.message, contains("Feature disabled"));
        expect(logger.events.last.level, Level.info);
        expect(
          logger.events.last.metadata?[MockFeature.test.toString()],
          "❌",
        );
      });

      test("dispose closes stream and future subscribers still receive events",
          () async {
        featureFlags.dispose();

        final event = expectLater(
          featureFlags.enabledFeaturesChanges,
          emitsThrough(contains(MockFeature.another)),
        );

        featureFlags.enableFeature(MockFeature.another);
        await event;
      });
    });
  });
}

enum MockFeature {
  test,
  another,
}
