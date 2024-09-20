import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";

part "authentication_enums.dart";
part "authentication_interface.dart";

/// Provides a standard interface to handle authentication-related tasks.
///
/// To get started, first ensure that an `ArcaneAuthInterface` has been
/// registered.
class ArcaneAuthenticationService extends ArcaneService {
  ArcaneAuthenticationService._internal();

  static final ArcaneAuthenticationService _instance =
      ArcaneAuthenticationService._internal();

  /// Provides access to the singleton instance of this service.
  static ArcaneAuthenticationService get I => _instance;

  AuthenticationStatus _status = AuthenticationStatus.unauthenticated;

  /// Returns the current `AuthenticationStatus`.
  ///
  /// Available values:
  /// - `authenticated`: The user has successfully authenticated and is logged in.
  /// - `unauthenticated`: The user has not yet logged in.
  /// - `debug`: Debug mode has been enabled, enabling development features.
  AuthenticationStatus get status => _status;

  static ArcaneAuthInterface? _authInterface;

  /// Provides direct access to the registered `ArcaneAuthInterface`, if one has
  /// been registered.
  ArcaneAuthInterface get authInterface {
    assert(
      _authInterface != null,
      "No ArcaneAuthInterface has been registered",
    );
    return _authInterface!;
  }

  /// A shortcut to `status != AuthenticationStatus.unauthenticated`.
  bool get isAuthenticated => status != AuthenticationStatus.unauthenticated;

  /// Expose the ValueListenable so other widgets can listen to changes.
  ValueListenable<bool> get isSignedIn => ValueNotifier<bool>(isAuthenticated);

  /// Returns a JWT access token if the registered `ArcaneAuthInterface`
  /// provides one. This token is often used in the headers of HTTP requests
  /// to the backend API.
  Future<String?> get accessToken => authInterface.accessToken;

  /// Returns a JWT refresh token if the registered `ArcaneAuthInterface`
  /// provides one.
  Future<String?> get refreshToken => authInterface.refreshToken;

  /// Removes any registered `ArcaneAuthInterface` and resets all values to
  /// default.
  Future<void> reset() async {
    _authInterface = null;
    _status = AuthenticationStatus.unauthenticated;
    notifyListeners();
  }

  /// Registers an `ArcaneAuthInterface` within the `ArcaneAuthenticationService`.
  Future<void> registerInterface(ArcaneAuthInterface authInterface) async {
    if (_authInterface != null) {
      throw Exception("ArcaneAuthInterface has already been registered");
    }

    _authInterface = authInterface;
    await authInterface.init();
  }

  /// Sets `status` to `AuthenticationStatus.debug`. If `onDebugModeSet` has
  /// been specified, the method will be triggered after the new status has been
  /// set.
  Future<void> setDebug(
    BuildContext context, {
    Future<void> Function()? onDebugModeSet,
  }) async {
    ArcaneEnvironment? environment;

    try {
      environment = context.read<ArcaneEnvironment>();
      final Environment previousEnvironment = environment.state;

      if (previousEnvironment == Environment.debug) return;

      environment.enableDebugMode();

      final Environment currentEnvironment = environment.state;

      if (previousEnvironment == currentEnvironment) {
        throw Exception("Unable to switch to debug mode.");
      }

      _setStatus(AuthenticationStatus.debug);
      if (onDebugModeSet != null) await onDebugModeSet();
    } catch (_) {
      throw Exception("No ArcaneEnvironment found in BuildContext");
    }
  }

  /// Sets `status` to `AuthenticationStatus.normal`. If `onDebugModeUnset` has
  /// been specified, the method will be triggered after the new status has been
  /// set.
  Future<void> setNormal(
    BuildContext context, {
    Future<void> Function()? onDebugModeUnset,
  }) async {
    ArcaneEnvironment? environment;

    try {
      environment = context.read<ArcaneEnvironment>();
      final Environment previousEnvironment = environment.state;

      if (previousEnvironment == Environment.normal) return;

      environment.disableDebugMode();

      final Environment currentEnvironment = environment.state;

      if (previousEnvironment == currentEnvironment) {
        throw Exception("Unable to switch to normal mode.");
      }

      _setStatus(AuthenticationStatus.debug);
      if (onDebugModeUnset != null) await onDebugModeUnset();
    } catch (_) {
      throw Exception("No ArcaneEnvironment found in BuildContext");
    }
  }

  /// Sets `status` to `AuthenticationStatus.authenticated`.
  void setAuthenticated() {
    _setStatus(AuthenticationStatus.authenticated);
  }

  /// Sets `status` to `AuthenticationStatus.unauthenticated`.
  void setUnauthenticated() {
    _setStatus(AuthenticationStatus.unauthenticated);
  }

  void _setStatus(AuthenticationStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// Logs the current user out. Upon successful logout, `status` will be set to
  /// `AuthenticationStatus.unauthenticated`.
  Future<void> logOut({Future<void> Function()? onLoggedOut}) async {
    if (!isAuthenticated) return;

    assert(
      _authInterface != null,
      "No ArcaneAuthInterface has been registered",
    );

    final Result<void, String> loggedOut = await authInterface.logout();

    await loggedOut.fold(
      onSuccess: (_) async {
        setUnauthenticated();
        if (onLoggedOut != null) await onLoggedOut();
      },
      onError: (e) {
        throw Exception(e);
      },
    );
  }

  /// Attempts to log in the user using their `email` and `password`.
  /// Upon successful login, `status` will be set to
  /// `AuthenticationStatus.authenticated]` If `onLoggedIn` is specified, the
  /// method will run after the authentication status has been updated.
  /// When logging in with email and password, the user's email address will be
  /// cached in `ArcaneSecureStorage`.
  @Deprecated("Use `login` instead. Deprecated as of version 1.0.5")
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
    Future<void> Function()? onLoggedIn,
  }) async {
    if (status != AuthenticationStatus.unauthenticated) {
      return Result.error("Cannot sign in. Status is already ${status.name}.");
    }

    final Result<void, String> result =
        await authInterface.loginWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      setAuthenticated();
      if (onLoggedIn != null) await onLoggedIn();
    }

    return result;
  }

  /// Logs the user in using an optional, generic `T` type of input.
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    if (_authInterface == null) {
      return Result.error("No ArcaneAuthInterface has been registered");
    }

    final Result<void, String> result = await authInterface.login(
      input: input,
    );

    if (result.isSuccess) {
      setAuthenticated();
      if (onLoggedIn != null) await onLoggedIn();
    }

    return result;
  }

  /// Attempts to register a new account using the provided `email` and
  /// `password`. Upon success, returns a `SignUpStep` indicating the next step
  /// in the signup process as a `SignUpStep`.
  Future<Result<SignUpStep, String>> signup({
    required String email,
    required String password,
  }) async {
    if (_authInterface == null) {
      return Result.error("No ArcaneAuthInterface has been registered");
    }

    final Result<SignUpStep, String> result = await authInterface.signup(
      email: email,
      password: password,
    );

    return result;
  }

  /// Confirms the user's signup using their `email` and `confirmationCode`.
  /// Returns a `Result.ok(true)` if signup was successful.
  Future<Result<bool, String>> confirmSignup({
    required String email,
    required String confirmationCode,
  }) async {
    if (_authInterface == null) {
      return Result.error("No ArcaneAuthInterface has been registered");
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
    if (_authInterface == null) {
      return Result.error("No ArcaneAuthInterface has been registered");
    }

    return authInterface.resendVerificationCode(email);
  }

  /// Attempts to reset the user's password using their `email`. This method
  /// should be called twice. The first call will initialize the password reset
  /// process. In the first attempt, only the `email` is provided. The second
  /// call should include the `email`, as well as a `newPassword` and
  /// `confirmationCode`. If the second call is successful, the password will be
  /// reset.
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? confirmationCode,
  }) async {
    if (_authInterface == null) {
      return Result.error("No ArcaneAuthInterface has been registered");
    }

    final Result<bool, String> result = await authInterface.resetPassword(
      email: email,
      newPassword: newPassword,
      code: confirmationCode,
    );

    return result;
  }
}
