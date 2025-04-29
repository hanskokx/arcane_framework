import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneServiceProvider", () {
    late List<ArcaneService> testServices;

    setUp(() {
      testServices = [
        MockArcaneService(),
        AnotherMockService(),
      ];
    });

    testWidgets("provides services to widget tree", (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final provider = ArcaneServiceProvider.of(context);
              expect(provider?.serviceInstances, equals(testServices));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("serviceOfType extension returns correct service",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = context.serviceOfType<MockArcaneService>();
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("serviceOfType returns null for unregistered service",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = context.serviceOfType<UnregisteredService>();
              expect(service, isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test("of() throws when no provider is found", () {
      final context = MockBuildContext();
      expect(
        () => ArcaneServiceProvider.of(context),
        throwsException,
      );
    });

    testWidgets("updateShouldNotify always returns true", (tester) async {
      final provider = ArcaneServiceProvider(
        serviceInstances: testServices,
        child: const SizedBox(),
      );

      expect(
        provider.updateShouldNotify(
          ArcaneServiceProvider(
            serviceInstances: testServices,
            child: const SizedBox(),
          ),
        ),
        true,
      );
    });
  });
}

class MockArcaneService extends ArcaneService {}

class AnotherMockService extends ArcaneService {}

class UnregisteredService extends ArcaneService {}

class MockBuildContext extends Fake implements BuildContext {}
