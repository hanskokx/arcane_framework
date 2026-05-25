import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

enum TestFeature {
  alpha,
  beta,
}

void main() {
  setUp(() {
    Arcane.features.reset();
  });

  testWidgets("ArcaneApp provides ArcaneFeatureFlagProvider", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArcaneApp(
          child: Builder(
            builder: (context) {
              expect(ArcaneFeatureFlagProvider.maybeOf(context), isNotNull);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets("feature flag updates trigger rebuilds for dependent widgets",
      (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ArcaneApp(
          child: Builder(
            builder: (context) {
              final scope = context.featureFlags;
              buildCount++;
              final bool enabled = scope.isEnabled(TestFeature.alpha);
              return Text(enabled ? "enabled" : "disabled");
            },
          ),
        ),
      ),
    );

    expect(find.text("disabled"), findsOneWidget);
    expect(buildCount, 1);

    Arcane.features.enableFeature(TestFeature.alpha);
    await tester.pump();

    expect(find.text("enabled"), findsOneWidget);
    expect(buildCount, 2);

    Arcane.features.disableFeature(TestFeature.alpha);
    await tester.pump();

    expect(find.text("disabled"), findsOneWidget);
    expect(buildCount, 3);
  });

  testWidgets("scope helper methods can enable and disable features",
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArcaneApp(
          child: Builder(
            builder: (context) {
              final scope = context.featureFlags;
              return Column(
                children: [
                  Text(
                    scope.isEnabled(TestFeature.beta) ? "on" : "off",
                  ),
                  TextButton(
                    onPressed: () => scope.enableFeature(TestFeature.beta),
                    child: const Text("enable"),
                  ),
                  TextButton(
                    onPressed: () => scope.disableFeature(TestFeature.beta),
                    child: const Text("disable"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text("off"), findsOneWidget);

    await tester.tap(find.text("enable"));
    await tester.pump();
    expect(find.text("on"), findsOneWidget);

    await tester.tap(find.text("disable"));
    await tester.pump();
    expect(find.text("off"), findsOneWidget);
  });

  testWidgets("scope exposes notifier and stream for reactive consumers",
      (tester) async {
    late ArcaneFeatureFlagProvider scope;

    await tester.pumpWidget(
      MaterialApp(
        home: ArcaneApp(
          child: Builder(
            builder: (context) {
              scope = context.featureFlags;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(identical(scope.notifier, Arcane.features.notifier), true);
    expect(scope.enabledFeaturesChanges, isA<Stream<List<Enum>>>());
  });

  testWidgets("context fallback helpers work without ArcaneFeatureFlagProvider",
      (tester) async {
    Arcane.features.enableFeature(TestFeature.alpha);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          expect(context.maybeFeatureFlags, isNull);
          expect(context.isFeatureEnabled(TestFeature.alpha), isTrue);
          expect(context.isFeatureDisabled(TestFeature.beta), isTrue);
          return const SizedBox();
        },
      ),
    );
  });
}
