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
              expect(provider.registeredServices, containsAll(testServices));
              expect(
                provider.registeredServices
                    .whereType<ArcaneFeatureFlagService>(),
                isNotEmpty,
              );
              expect(
                provider.registeredServices
                    .whereType<ArcaneAuthenticationService>(),
                isNotEmpty,
              );
              expect(
                provider.registeredServices.whereType<ArcaneThemeService>(),
                isNotEmpty,
              );
              expect(
                provider.registeredServices
                    .whereType<ArcaneEnvironmentService>(),
                isNotEmpty,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("does not duplicate built-ins when explicitly provided",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: [Arcane.environment],
          child: Builder(
            builder: (context) {
              final provider = ArcaneServiceProvider.of(context);
              final environmentServices = provider.registeredServices
                  .whereType<ArcaneEnvironmentService>()
                  .toList();

              expect(environmentServices.length, 1);
              expect(environmentServices.single, same(Arcane.environment));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("ArcaneApp builder receives provider-aware context",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          builder: (context, child) {
            final provider = ArcaneServiceProvider.of(context);
            expect(provider.registeredServices, containsAll(testServices));
            return child ?? const SizedBox();
          },
          child: const SizedBox(),
        ),
      );
    });

    testWidgets("ArcaneApp supports builder-only usage", (tester) async {
      var builderCalled = false;

      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          builder: (context, _) {
            builderCalled = true;
            final provider = ArcaneServiceProvider.of(context);
            expect(provider.registeredServices, containsAll(testServices));
            return const SizedBox();
          },
        ),
      );

      expect(builderCalled, isTrue);
    });

    test("ArcaneApp asserts when both child and builder are missing", () {
      expect(
        () => ArcaneApp(),
        throwsA(isA<AssertionError>()),
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

    testWidgets("service<T> prefers provider services over built-in fallbacks",
        (tester) async {
      final providerService = MockArcaneService();

      await tester.pumpWidget(
        ArcaneApp(
          services: [providerService],
          child: Builder(
            builder: (context) {
              final service = context.service<ArcaneService>();
              expect(service, same(providerService));
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

    testWidgets("maybeOf returns null when provider is missing",
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ArcaneServiceProvider.maybeOf(context), isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("of asserts when provider is missing", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => ArcaneServiceProvider.of(context),
                throwsA(isA<AssertionError>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
        "requiredServiceOfType returns service and asserts when missing",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = ArcaneServiceProvider.requiredServiceOfType<
                  MockArcaneService>(context);
              expect(service, isA<MockArcaneService>());

              expect(
                () => ArcaneServiceProvider.requiredServiceOfType<
                    UnregisteredService>(context),
                throwsA(isA<AssertionError>()),
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("addService replaces same runtime type", (tester) async {
      late ArcaneServiceProvider provider;
      final first = MockArcaneService();
      final replacement = MockArcaneService();

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(
            serviceInstances: [first],
            child: Builder(
              builder: (context) {
                provider = ArcaneServiceProvider.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      provider.addService(replacement);
      await tester.pump();

      final matches =
          provider.registeredServices.whereType<MockArcaneService>();
      expect(matches.length, 1);
      expect(matches.single, same(replacement));
    });

    testWidgets("removeService removes matching type and reports status",
        (tester) async {
      late ArcaneServiceProvider provider;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(
            serviceInstances: [MockArcaneService(), AnotherMockService()],
            child: Builder(
              builder: (context) {
                provider = ArcaneServiceProvider.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final removed = provider.removeService<MockArcaneService>();
      await tester.pump();

      expect(removed, isTrue);
      expect(
        provider.registeredServices.whereType<MockArcaneService>(),
        isEmpty,
      );

      final secondRemoval = provider.removeService<MockArcaneService>();
      expect(secondRemoval, isFalse);
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

    testWidgets("Arcane.service.ofType<T> helper works", (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = Arcane.service.ofType<MockArcaneService>(context);
              expect(service, isNotNull);
              expect(service, isA<MockArcaneService>());

              final missing = Arcane.service.ofType<UnregisteredService>(
                context,
              );
              expect(missing, isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("Arcane.service.requiredOfType<T> helper works",
        (tester) async {
      await tester.pumpWidget(
        ArcaneApp(
          services: testServices,
          child: Builder(
            builder: (context) {
              final service = Arcane.service.requiredOfType<MockArcaneService>(
                context,
              );
              expect(service, isA<MockArcaneService>());

              expect(
                () =>
                    Arcane.service.requiredOfType<UnregisteredService>(context),
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
