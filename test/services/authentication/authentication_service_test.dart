import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";

import "authentication_service_test.mocks.dart";

@GenerateMocks([
  ArcaneAuthInterface,
  ArcaneEnvironmentProvider,
])
void main() {
  late ArcaneAuthInterface mockInterface;

  group("ArcaneAuthenticationService", () {
    setUp(() async {
      // Initialize mocks
      mockInterface = MockArcaneAuthInterface();

      // Initialize the service
      await ArcaneAuthenticationService.I.reset();

      // Set up default mock behaviors
      when(mockInterface.login(input: anyNamed("input"))).thenAnswer(
        (_) async => Result.ok(null),
      );
      when(mockInterface.logout()).thenAnswer(
        (_) async => Result.ok(null),
      );
      when(mockInterface.init()).thenAnswer(
        (_) async {},
      );

      await ArcaneAuthenticationService.I.registerInterface(mockInterface);
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
      // Reset the mock behavior for this specific test
      when(mockInterface.login(input: anyNamed("input")))
          .thenAnswer((_) async => Result.error("error"));

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
  });
}
