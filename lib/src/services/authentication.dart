import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";

class ArcaneAuthenticationService extends ArcaneService {
  ArcaneAuthenticationService._internal();

  static bool _mocked = false;
  static final ArcaneAuthenticationService _instance =
      ArcaneAuthenticationService._internal();
  static ArcaneAuthenticationService get I => _instance;

  AuthenticationStatus _status = AuthenticationStatus.unauthenticated;
  AuthenticationStatus get status => _status;

  static late ArcaneAuthInterface _authInterface;
  ArcaneAuthInterface get authInterface => _authInterface;

  bool get isAuthenticated => status == AuthenticationStatus.authenticated;
  Future<bool> get isSignedIn => authInterface.isSignedIn;

  Future<String?> get accessToken => authInterface.accessToken;
  Future<String?> get refreshToken => authInterface.refreshToken;

  static ArcaneSecureStorage get _storage => GetIt.I<ArcaneSecureStorage>();

  Future<void> registerInterface(ArcaneAuthInterface authInterface) async {
    _authInterface = authInterface;
    await authInterface.init();
  }

  /// Sets [status] to [AuthenticationStatus.debug].
  Future<void> setDebug(
    BuildContext context,
    Future<void> Function()? onDebugModeSet,
  ) async {
    if (_mocked) return;
    if (ArcaneFeature.accountDebugMode.disabled) return;

    Arcane.log(
      "!!!!! DEBUG MODE ENABLED !!!!!",
      level: Level.fatal,
    );

    ArcaneEnvironment? environment;

    try {
      environment = context.read<ArcaneEnvironment>();

      await environment.enableDebugMode(onDebugModeSet);
    } catch (_) {
      Arcane.logger.log(
        "No ArcaneEnvironment found in BuildContext",
        level: Level.error,
      );
    }

    _setStatus(AuthenticationStatus.debug);
  }

  /// Sets [status] to [AuthenticationStatus.authenticated].
  void setAuthenticated() {
    if (_mocked) return;

    _setStatus(AuthenticationStatus.authenticated);
  }

  /// Sets [status] to [AuthenticationStatus.unauthenticated] and triggers a
  /// refresh in [AppRouter], effectively returning a logged out user to the
  /// welcome screen.
  void setUnauthenticated() {
    if (_mocked) return;

    _setStatus(AuthenticationStatus.unauthenticated);
  }

  void _setStatus(AuthenticationStatus newStatus) {
    if (_mocked) return;

    _status = newStatus;
    notifyListeners();
  }

  /// Logs the current user out. Upon successful logout, [status] will be set to
  /// [AuthenticationStatus.unauthenticated].
  Future<void> logOut({required VoidCallback onLoggedOut}) async {
    if (_mocked) return;
    if (status == AuthenticationStatus.unauthenticated) return;

    final Result<void, String> loggedOut = await authInterface.logout();

    await loggedOut.fold(
      onSuccess: (_) async {
        await _storage.deleteAll();

        setUnauthenticated();

        Arcane.log(
          "Sign out completed successfully",
          level: Level.info,
        );

        onLoggedOut();
      },
      onError: (e) {
        Arcane.log(
          "Error signing user out: $e",
          level: Level.error,
        );
      },
    );
  }

  /// Attempts to log in the user using their [email] and [password].
  /// Upon successful login, [status] will be set to
  /// [AuthenticationStatus.authenticated].
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (status != AuthenticationStatus.unauthenticated) {
      return Result.error("Already signed in");
    }

    final Result<void, String> result =
        await authInterface.loginWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.isFailure) {
      Arcane.log(
        "Error signing in: ${result.error}",
        level: Level.error,
      );
    }

    if (result.isSuccess) {
      await _storage.setValue(ArcaneSecureStorage.emailKey, email);
      setAuthenticated();
    }

    return result;
  }

  /// Attempts to register a new account using the provided [email] and
  /// [password]. Upon success, returns a [SignUpStep] indicating the next step
  /// in the signup process.
  Future<Result<SignUpStep, String>> signup({
    required String email,
    required String password,
  }) async {
    if (status == AuthenticationStatus.debug) {
      return Result.error("Operation not supported in debug mode.");
    }

    final Result<SignUpStep, String> result = await authInterface.signup(
      email: email,
      password: password,
    );

    if (result.isFailure) {
      Arcane.log(
        "Error signing up: ${result.error}",
        level: Level.error,
      );

      return Result.error(result.error);
    }

    if (result.value == SignUpStep.confirmSignUp) {
      Arcane.log(
        "User account created successfully but confirmation is required.",
        level: Level.info,
      );
    }

    return result;
  }

  /// Confirms the user's signup using their [email] and [confirmationCode].
  /// Returns a [Result.ok(true)] if signup was successful.
  Future<Result<bool, String>> confirmSignup({
    required String email,
    required String confirmationCode,
  }) async {
    if (status == AuthenticationStatus.debug) {
      return Result.error("Operation not supported in debug mode.");
    }

    final Result<bool, String> result = await authInterface.confirmSignup(
      username: email,
      confirmationCode: confirmationCode,
    );

    return result;
  }

  /// Re-sends a verification code to be used when confirming the user's
  /// registration.
  Future<Result<String, String>> resendVerificationCode(String email) async {
    if (ArcaneAuthenticationService.I.status == AuthenticationStatus.debug) {
      return Result.error("Operation not supported in debug mode.");
    }

    return authInterface.resendVerificationCode(email);
  }

  /// Attempts to reset the user's password using their [email]. This method
  /// should be called twice. The first call will initialize the password reset
  /// process. In the first attempt, only the [email] is provided. The second
  /// call should include the [email], as well as a [newPassword] and
  /// [confirmationCode]. If the second call is successful, the password will be
  /// reset.
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? confirmationCode,
  }) async {
    if (status == AuthenticationStatus.debug) {
      return Result.error("Operation not supported in debug mode.");
    }

    final Result<bool, String> result = await authInterface.resetPassword(
      email: email,
      newPassword: newPassword,
      code: confirmationCode,
    );

    return result;
  }

  @visibleForTesting
  static void setMocked() {
    _mocked = true;
  }
}

enum AuthenticationStatus {
  authenticated,
  unauthenticated,
  debug,
  ;

  bool get isDebug => this == debug;
  bool get isAuthenticated => this == authenticated;
  bool get isUnauthenticated => this == unauthenticated;
}

abstract class ArcaneAuthInterface {
  /// Returns true if the user is signed in.
  Future<bool> get isSignedIn;

  /// Returns the access token.
  Future<String?> get accessToken;

  /// Returns the refresh token.
  Future<String?> get refreshToken;

  /// Initializes the auth interface
  Future<void> init();

  /// Logs the user out.
  Future<Result<void, String>> logout();

  /// Logs the user in using an email address and password.
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Re-sends a verification code to the user's [email] address.
  Future<Result<String, String>> resendVerificationCode(
    String email,
  );

  /// Signs a user up with a username, password, and email.
  Future<Result<SignUpStep, String>> signup({
    required String password,
    required String email,
  });

  /// Confirms a user's signup using an [username] and the [confirmationCode]
  /// they received from the signup process.
  Future<Result<bool, String>> confirmSignup({
    required String username,
    required String confirmationCode,
  });

  /// Resets a user's password using an [email] address and the [code] they
  /// received from the reset password process.
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? code,
  });
}

enum SignUpStep {
  confirmSignUp,
  done,
}

enum Environment { debug, normal }

class ArcaneEnvironment extends Cubit<Environment> {
  ArcaneEnvironment() : super(Environment.normal);

  Future<void> enableDebugMode(Future<void> Function()? onDemoModeSet) async {
    if (onDemoModeSet != null) await onDemoModeSet();

    emit(Environment.debug);
  }
}

class ArcaneEnvironmentProvider extends StatelessWidget {
  final Widget child;
  const ArcaneEnvironmentProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ArcaneEnvironment(),
      child: child,
    );
  }
}
