import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

class _TestService extends ArcaneService {
  _TestService(this.label);

  final String label;
}

void main() {
  setUpAll(() {
    Arcane.features.reset();
    Arcane.theme.reset();
    Arcane.environment.reset();
  });

  tearDown(() {
    ArcaneServices.I.clear();
  });

  group("ArcaneServiceProvider", () {
    testWidgets("maybeOf is null outside a provider and non-null inside", (
      WidgetTester tester,
    ) async {
      late BuildContext outerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              outerContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(ArcaneServiceProvider.maybeOf(outerContext), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(child: const SizedBox()),
        ),
      );
      final BuildContext innerContext = tester.element(find.byType(SizedBox));
      expect(ArcaneServiceProvider.maybeOf(innerContext), isNotNull);
    });

    testWidgets("addService and removeService update the registry", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(child: const SizedBox()),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));
      final ArcaneServiceProvider provider = ArcaneServiceProvider.of(context);

      expect(context.service<_TestService>(), isNull);

      provider.addService(_TestService("blue"));
      await tester.pump();
      expect(context.service<_TestService>()?.label, "blue");

      provider.addService(_TestService("red"));
      await tester.pump();
      expect(context.service<_TestService>()?.label, "red");
      expect(
        ArcaneServices.I.services.whereType<_TestService>(),
        hasLength(1),
      );

      expect(provider.removeService<_TestService>(), isTrue);
      await tester.pump();
      expect(context.service<_TestService>(), isNull);
    });

    testWidgets("setServices replaces the whole registry", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(child: const SizedBox()),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));
      final ArcaneServiceProvider provider = ArcaneServiceProvider.of(context);

      provider.setServices(<ArcaneService>[
        _TestService("green"),
        _TestService("yellow"),
      ]);
      await tester.pump();

      expect(
        ArcaneServices.I.services.whereType<_TestService>().map(
          (_TestService service) => service.label,
        ),
        <String>["green", "yellow"],
      );
    });

    testWidgets("requiredService throws when the service is absent", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(child: const SizedBox()),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));

      expect(
        () => context.requiredService<_TestService>(),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets("dependent widgets rebuild when services change", (
      WidgetTester tester,
    ) async {
      int rebuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneServiceProvider(
            child: Builder(
              builder: (BuildContext context) {
                rebuilds++;
                final _TestService? service = context.service<_TestService>();
                return Text(service?.label ?? "none");
              },
            ),
          ),
        ),
      );

      expect(find.text("none"), findsOneWidget);
      final int initialRebuilds = rebuilds;

      ArcaneServices.I.add(_TestService("purple"));
      await tester.pump();

      expect(find.text("purple"), findsOneWidget);
      expect(rebuilds, greaterThan(initialRebuilds));
    });

    testWidgets("service falls back to built-in singletons", (
      WidgetTester tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext innerContext) {
              context = innerContext;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        context.service<ArcaneThemeService>(),
        same(Arcane.theme),
      );
    });
  });

  group("ArcaneApp", () {
    testWidgets("registers built-in services into the registry", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ArcaneApp(builder: (BuildContext context) => const SizedBox()),
      );

      final Iterable<ArcaneService> services = ArcaneServices.I.services;
      expect(services, contains(isA<ArcaneFeatureFlagService>()));
      expect(services, contains(isA<ArcaneAuthenticationService>()));
      expect(services, contains(isA<ArcaneThemeService>()));
      expect(services, contains(isA<ArcaneEnvironmentService>()));
    });
  });
}
