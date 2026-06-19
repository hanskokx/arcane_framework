import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneEnvironment", () {
    setUp(() {
      Arcane.environment.reset();
    });

    testWidgets("maybeOf returns null without provider", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ArcaneEnvironment.maybeOf(context), isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets("of throws without provider", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => ArcaneEnvironment.of(context),
                throwsA(isA<StateError>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test("updateShouldNotify changes only when environment changes", () {
      final normalA = ArcaneEnvironment(
        environment: Environment.normal,
        switchEnvironment: (_) {},
        child: const SizedBox(),
      );
      final normalB = ArcaneEnvironment(
        environment: Environment.normal,
        switchEnvironment: (_) {},
        child: const SizedBox(),
      );
      final debug = ArcaneEnvironment(
        environment: Environment.debug,
        switchEnvironment: (_) {},
        child: const SizedBox(),
      );

      expect(normalA.updateShouldNotify(normalB), isFalse);
      expect(debug.updateShouldNotify(normalB), isTrue);
    });
  });

  group("ArcaneEnvironmentProvider", () {
    setUp(() {
      Arcane.environment.reset();
    });

    testWidgets("uses widget initial environment on init", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            environment: Environment.debug,
            child: Builder(
              builder: (context) {
                final env = ArcaneEnvironment.of(context);
                expect(env.environment, Environment.debug);
                expect(env.current, Environment.debug);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets("setEnvironment updates service and inherited widget",
        (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      ArcaneEnvironment.of(capturedContext).setEnvironment(Environment.debug);
      await tester.pump();
      expect(Arcane.environment.current, Environment.debug);
    });

    testWidgets("enableDebugMode and disableDebugMode proxy correctly",
        (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      ArcaneEnvironment.of(capturedContext).enableDebugMode();
      await tester.pump();
      expect(Arcane.environment.current, Environment.debug);

      ArcaneEnvironment.of(capturedContext).disableDebugMode();
      await tester.pump();
      expect(Arcane.environment.current, Environment.normal);
    });

    testWidgets("provider rebuilds when service environment changes",
        (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            child: Builder(
              builder: (context) {
                buildCount++;
                // ignore: unnecessary_statements
                ArcaneEnvironment.of(context).environment;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      Arcane.environment.setEnvironment(Environment.debug);
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets(
      "state enableDebugMode updates to debug and no-ops when already debug",
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ArcaneEnvironmentProvider(
              child: Builder(
                builder: (context) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        final ArcaneEnvironmentModeController state =
            tester.state<State<ArcaneEnvironmentProvider>>(
          find.byType(ArcaneEnvironmentProvider),
        ) as ArcaneEnvironmentModeController;

        expect(Arcane.environment.current, Environment.normal);

        state.enableDebugMode();
        await tester.pump();
        expect(Arcane.environment.current, Environment.debug);

        state.enableDebugMode();
        await tester.pump();
        expect(Arcane.environment.current, Environment.debug);
      },
    );

    testWidgets(
      "state disableDebugMode updates to normal and no-ops when already normal",
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ArcaneEnvironmentProvider(
              environment: Environment.debug,
              child: Builder(
                builder: (context) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        final ArcaneEnvironmentModeController state =
            tester.state<State<ArcaneEnvironmentProvider>>(
          find.byType(ArcaneEnvironmentProvider),
        ) as ArcaneEnvironmentModeController;

        expect(Arcane.environment.current, Environment.debug);

        state.disableDebugMode();
        await tester.pump();
        expect(Arcane.environment.current, Environment.normal);

        state.disableDebugMode();
        await tester.pump();
        expect(Arcane.environment.current, Environment.normal);
      },
    );
  });
}
