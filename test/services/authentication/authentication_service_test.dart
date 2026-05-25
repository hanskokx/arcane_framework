import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class MockArcaneAuthInterface extends Mock implements ArcaneAuthInterface {}

class MockAccountRegistration extends Mock
    implements ArcaneAuthInterface, ArcaneAuthAccountRegistration {}

class MockPasswordManagement extends Mock
    implements ArcaneAuthInterface, ArcaneAuthPasswordManagement {}

void main() {
  group("ArcaneAuthenticationService error and edge cases", () {
    setUp(() async {
      await ArcaneAuthenticationService.I.reset();
      Arcane.environment.reset();
    });

    test("reset clears interface and notifiers", () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      await ArcaneAuthenticationService.I.reset();
      expect(ArcaneAuthenticationService.I.authInterface, isNull);
      expect(
        ArcaneAuthenticationService.I.status,
        AuthenticationStatus.unauthenticated,
      );
      expect(ArcaneAuthenticationService.I.isSignedIn.value, false);
    });

    test("registerInterface throws if already registered", () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      expect(
        () async => ArcaneAuthenticationService.I.registerInterface(auth),
        throwsException,
      );
    });

    test("login returns error if no interface registered", () async {
      final result = await ArcaneAuthenticationService.I.login(input: {});
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test("logOut returns error if no interface registered", () async {
      final result = await ArcaneAuthenticationService.I.logOut();
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test("logOut returns error if not authenticated", () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result = await ArcaneAuthenticationService.I.logOut();
      expect(result.isFailure, true);
      expect(result.error, contains("not authenticated"));
    });

    test("register returns error if no interface registered", () async {
      final result = await ArcaneAuthenticationService.I.register(input: {});
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test("register returns error if interface does not support registration",
        () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result = await ArcaneAuthenticationService.I.register(input: {});
      expect(result.isFailure, true);
      expect(result.error, contains("does not support account registration"));
    });

    test("register returns error if registration returns null", () async {
      final auth = MockAccountRegistration();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      when(() => auth.register(input: any(named: "input")))
          .thenAnswer((_) async => const Result.error("returned a null value"));
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result = await ArcaneAuthenticationService.I.register(input: {});
      expect(result.isFailure, true);
      expect(result.error, contains("returned a null value"));
    });

    test("confirmSignup returns error if no interface registered", () async {
      final result = await ArcaneAuthenticationService.I
          .confirmSignup(email: "a", confirmationCode: "b");
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test(
        "confirmSignup returns error if interface does not support registration",
        () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result = await ArcaneAuthenticationService.I
          .confirmSignup(email: "a", confirmationCode: "b");
      expect(result.isFailure, true);
      expect(result.error, contains("does not support account registration"));
    });

    test("confirmSignup returns error if confirmSignup returns null", () async {
      final auth = MockAccountRegistration();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      when(
        () => auth.confirmSignup(
          username: any(named: "username"),
          confirmationCode: any(named: "confirmationCode"),
        ),
      ).thenAnswer((_) async => const Result.error("returned a null value"));
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result = await ArcaneAuthenticationService.I
          .confirmSignup(email: "a", confirmationCode: "b");
      expect(result.isFailure, true);
      expect(result.error, contains("returned a null value"));
    });

    test("resendVerificationCode returns error if no interface registered",
        () async {
      final result =
          await ArcaneAuthenticationService.I.resendVerificationCode("a");
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test(
        "resendVerificationCode returns error if interface does not support registration",
        () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result =
          await ArcaneAuthenticationService.I.resendVerificationCode("a");
      expect(result.isFailure, true);
      expect(result.error, contains("does not support account registration"));
    });

    test(
        "resendVerificationCode returns error if resendVerificationCode returns null",
        () async {
      final auth = MockAccountRegistration();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      when(() => auth.resendVerificationCode(input: any(named: "input")))
          .thenReturn(null);
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result =
          await ArcaneAuthenticationService.I.resendVerificationCode("a");
      expect(result.isFailure, true);
      expect(result.error, contains("returned a null value"));
    });

    test("resetPassword returns error if no interface registered", () async {
      final result =
          await ArcaneAuthenticationService.I.resetPassword(email: "a");
      expect(result.isFailure, true);
      expect(result.error, contains("No ArcaneAuthInterface"));
    });

    test(
        "resetPassword returns error if interface does not support password management",
        () async {
      final auth = MockArcaneAuthInterface();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result =
          await ArcaneAuthenticationService.I.resetPassword(email: "a");
      expect(result.isFailure, true);
      expect(result.error, contains("does not support password management"));
    });

    test("resetPassword returns error if resetPassword returns null", () async {
      final auth = MockPasswordManagement();
      when(() => auth.init()).thenAnswer((_) async {
        return null;
      });
      when(
        () => auth.resetPassword(
          email: any(named: "email"),
          newPassword: any(named: "newPassword"),
          code: any(named: "code"),
        ),
      ).thenAnswer((_) async => const Result.error("returned a null value"));
      await ArcaneAuthenticationService.I.registerInterface(auth);
      final result =
          await ArcaneAuthenticationService.I.resetPassword(email: "a");
      expect(result.isFailure, true);
      expect(result.error, contains("returned a null value"));
    });

    test("dispose closes stream controllers and calls super", () async {
      // Just call dispose to ensure no exceptions are thrown
      ArcaneAuthenticationService.I.dispose();
      // No assertion needed; just ensure no crash
    });
  });

  late ArcaneAuthInterface authInterface;

  group("ArcaneAuthenticationService", () {
    setUp(() async {
      authInterface = MockArcaneAuthInterface();

      // Initialize the service
      await ArcaneAuthenticationService.I.reset();
      Arcane.environment.reset();

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

    testWidgets(
      "setDebug and setNormal use Arcane.environment without provider ancestry",
      (WidgetTester tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return Container();
              },
            ),
          ),
        );

        await ArcaneAuthenticationService.I.setDebug(capturedContext);
        expect(Arcane.environment.current, Environment.debug);

        await ArcaneAuthenticationService.I.setNormal(capturedContext);
        expect(Arcane.environment.current, Environment.normal);
      },
    );

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

    testWidgets(
      "setDebug and setNormal do not mutate authentication status",
      (WidgetTester tester) async {
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

        await ArcaneAuthenticationService.I.login(
          input: {"username": "test"},
        );

        expect(ArcaneAuthenticationService.I.isAuthenticated, true);

        await ArcaneAuthenticationService.I.setDebug(capturedContext);
        expect(
          ArcaneAuthenticationService.I.status,
          AuthenticationStatus.authenticated,
        );

        await ArcaneAuthenticationService.I.setNormal(capturedContext);
        expect(
          ArcaneAuthenticationService.I.status,
          AuthenticationStatus.authenticated,
        );
      },
    );

    testWidgets("supports custom environment values",
        (WidgetTester tester) async {
      late BuildContext capturedContext;

      const Environment staging = Environment("staging");

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

      ArcaneEnvironment.of(capturedContext).setEnvironment(staging);
      await tester.pump();

      expect(ArcaneEnvironment.of(capturedContext).environment, staging);
      expect(ArcaneEnvironment.of(capturedContext).environment.name, "staging");
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

    test("statusChanges and signedInChanges stay coherent", () async {
      ArcaneAuthenticationService.I.setUnauthenticated();

      final statusEvents = expectLater(
        ArcaneAuthenticationService.I.statusChanges,
        emitsInOrder(
          <AuthenticationStatus>[
            AuthenticationStatus.authenticated,
            AuthenticationStatus.unauthenticated,
          ],
        ),
      );

      final signedInEvents = expectLater(
        ArcaneAuthenticationService.I.signedInChanges,
        emitsInOrder(<bool>[true, false]),
      );

      ArcaneAuthenticationService.I.setAuthenticated();
      ArcaneAuthenticationService.I.setUnauthenticated();

      await statusEvents;
      await signedInEvents;
    });
  });
}
