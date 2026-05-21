import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class MockArcaneAuthInterface extends Mock implements ArcaneAuthInterface {}

void main() {
  late ArcaneAuthInterface authInterface;

  group("ArcaneAuthenticationService", () {
    setUp(() async {
      authInterface = MockArcaneAuthInterface();

      // Initialize the service
      await ArcaneAuthenticationService.I.reset();

      when(() => authInterface.init()).thenAnswer((_) async {});

      when(
        () => authInterface.login<Map<String, String>>(
          input: any(named: "input"),
          onLoggedIn: any(named: "onLoggedIn"),
        ),
      ).thenAnswer((_) async => const Result.ok(null));

      when(
        () => authInterface.logout(
          onLoggedOut: any(named: "onLoggedOut"),
        ),
      ).thenAnswer((_) async => const Result.ok(null));

      await ArcaneAuthenticationService.I.registerInterface(authInterface);
    });

    testWidgets("login with success", (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            environment: Environment.normal,
            child: Builder(
              builder: (context) {
                return Container();
              },
            ),
          ),
        ),
      );
      final result = await ArcaneAuthenticationService.I.login(
        input: {"username": "test"},
      );
      expect(result.isSuccess, true);
      expect(
        ArcaneAuthenticationService.I.status,
        equals(AuthenticationStatus.authenticated),
      );
    });

    testWidgets("login with failure", (WidgetTester tester) async {
      when(
        () => authInterface.login<Map<String, String>>(
          input: any(named: "input"),
          onLoggedIn: any(named: "onLoggedIn"),
        ),
      ).thenAnswer((_) async => const Result.error("error"));

      final result = await ArcaneAuthenticationService.I
          .login(input: {"username": "test"});
      expect(result.isFailure, true);
      expect(
        ArcaneAuthenticationService.I.status,
        equals(AuthenticationStatus.unauthenticated),
      );
    });

    testWidgets("logout with success", (WidgetTester tester) async {
      ArcaneAuthenticationService.I.setAuthenticated();
      final result = await ArcaneAuthenticationService.I.logOut();
      expect(result.isSuccess, true);
      expect(
        ArcaneAuthenticationService.I.status,
        equals(AuthenticationStatus.unauthenticated),
      );
    });

    testWidgets("setDebug enables debug mode", (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      ArcaneEnvironment.of(capturedContext).enableDebugMode();
      await tester.pump();
      expect(
        ArcaneEnvironment.of(capturedContext).environment,
        equals(Environment.debug),
      );
    });

    testWidgets("setNormal disables debug mode", (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneEnvironmentProvider(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      ArcaneEnvironment.of(capturedContext).enableDebugMode();
      await tester.pump();

      expect(
        ArcaneEnvironment.of(capturedContext).environment,
        equals(Environment.debug),
      );

      ArcaneEnvironment.of(capturedContext).disableDebugMode();
      await tester.pump();

      expect(
        ArcaneEnvironment.of(capturedContext).environment,
        equals(Environment.normal),
      );
    });

    test("statusChanges emits authentication updates", () async {
      final statusEvent = expectLater(
        ArcaneAuthenticationService.I.statusChanges,
        emits(AuthenticationStatus.authenticated),
      );

      ArcaneAuthenticationService.I.setAuthenticated();
      await statusEvent;
    });

    test("signedInChanges emits signed-in updates", () async {
      final signedInEvent = expectLater(
        ArcaneAuthenticationService.I.signedInChanges,
        emits(true),
      );

      ArcaneAuthenticationService.I.setAuthenticated();
      await signedInEvent;
    });

    test("statusChanges works after listener cancellation", () async {
      final firstSubscription =
          ArcaneAuthenticationService.I.statusChanges.listen((_) {});
      await firstSubscription.cancel();

      // Ensure a deterministic baseline before asserting the next stream event.
      ArcaneAuthenticationService.I.setUnauthenticated();

      final secondEvent = expectLater(
        ArcaneAuthenticationService.I.statusChanges,
        emits(AuthenticationStatus.authenticated),
      );

      ArcaneAuthenticationService.I.setAuthenticated();
      await secondEvent;
    });
  });
}
