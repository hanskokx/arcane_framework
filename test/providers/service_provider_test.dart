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
              expect(provider.registeredServices, equals(testServices));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("static serviceOfType<T> method returns correct service",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service =
                  ArcaneServiceProvider.serviceOfType<MockArcaneService>(
                context,
              );
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
        "static serviceOfType<T> method returns correct service and returns null when not found",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              // Should find this service
              final service =
                  ArcaneServiceProvider.serviceOfType<MockArcaneService>(
                context,
              );

              expect(service, isA<MockArcaneService>());

              // Returns null for unregistered services
              expect(
                ArcaneServiceProvider.serviceOfType<UnregisteredService>(
                  context,
                ),
                isNull,
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("service<T> extension returns correct service", (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = context.service<MockArcaneService>();
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
        "requiredService<T> extension returns correct service and throws when not found",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              // Should find this service
              final service = context.requiredService<MockArcaneService>();
              expect(service, isA<MockArcaneService>());

              // Should throw for missing service
              expect(
                () => context.requiredService<UnregisteredService>(),
                throwsA(isA<AssertionError>()),
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("service<T> returns null for unregistered service",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = context.service<UnregisteredService>();
              expect(service, isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("legacy serviceOfType method still works but is deprecated",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              // ignore: deprecated_member_use_from_same_package
              final service = context.serviceOfType<MockArcaneService>();
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("service updates trigger rebuilds", (tester) async {
      late ArcaneServiceProvider provider;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(
            serviceInstances: testServices,
            child: Builder(
              builder: (context) {
                provider = ArcaneServiceProvider.of(context);
                buildCount++;
                // Access a service to create dependency
                context.service<MockArcaneService>();
                return const Text("Test");
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Update services and verify rebuild
      provider.setServices([MockArcaneService(), AnotherMockService()]);
      await tester.pump();
      expect(buildCount, 2);

      // Add a service and verify rebuild
      provider.addService(UnregisteredService());
      await tester.pump();
      expect(buildCount, 3);
    });

    testWidgets("ArcaneService.of<T> static helper works", (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = ArcaneService.ofType<MockArcaneService>(context);
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("ArcaneService.requiredOf<T> static helper works",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service =
                  ArcaneService.requiredOfType<MockArcaneService>(context);
              expect(service, isA<MockArcaneService>());

              expect(
                () =>
                    ArcaneService.requiredOfType<UnregisteredService>(context),
                throwsA(isA<AssertionError>()),
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

// Mock classes for testing
class MockArcaneService extends ArcaneService {}

class AnotherMockService extends ArcaneService {}

class UnregisteredService extends ArcaneService {}

class MockBuildContext extends Fake implements BuildContext {}
