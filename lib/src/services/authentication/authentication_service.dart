import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";

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

  final ValueNotifier<AuthenticationStatus> _notifier =
      ValueNotifier<AuthenticationStatus>(AuthenticationStatus.unauthenticated);

  /// A `ValueNotifier` that emits the current `AuthenticationStatus`.
  ValueNotifier<AuthenticationStatus> get notifier => _notifier;

  StreamController<AuthenticationStatus>? _statusStreamController;

  StreamController<AuthenticationStatus> get _statusController {
    _statusStreamController ??=
        StreamController<AuthenticationStatus>.broadcast();
    return _statusStreamController!;
  }

  /// Stream of authentication status updates.
  Stream<AuthenticationStatus> get statusChanges => I._statusController.stream;

  /// Returns the current `AuthenticationStatus` as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [notifier] (for `ValueListenableBuilder`) or
  /// [statusChanges] (for streams) when you need reactive updates.
  ///
  /// Available values:
  /// - `authenticated`: The user has successfully authenticated and is logged in.
  /// - `unauthenticated`: The user has not yet logged in.
  AuthenticationStatus get status => _notifier.value;

  static ArcaneAuthInterface? _authInterface;

  /// Provides direct access to the registered `ArcaneAuthInterface`, if one has
  /// been registered.
  ArcaneAuthInterface? get authInterface => _authInterface;

  /// Returns `true` when the current status is authenticated.
  bool get isAuthenticated => status == AuthenticationStatus.authenticated;

  final ValueNotifier<bool> _isSignedIn = ValueNotifier<bool>(false);

  /// A `ValueNotifier` that emits `true` if the user is currently signed in.
  ValueNotifier<bool> get isSignedIn => _isSignedIn;

  StreamController<bool>? _signedInStreamController;

  StreamController<bool> get _signedInController {
    _signedInStreamController ??= StreamController<bool>.broadcast();
    return _signedInStreamController!;
  }

  /// Stream of signed-in boolean updates.
  Stream<bool> get signedInChanges => I._signedInController.stream;

  /// Returns a JWT access token if the registered `ArcaneAuthInterface`
  /// provides one. This token is often used in the headers of HTTP requests
  /// to the backend API.
  Future<String?> get accessToken async =>
      await authInterface?.accessToken ?? Future.value("");

  /// Returns a JWT refresh token if the registered `ArcaneAuthInterface`
  /// provides one.
  Future<String?> get refreshToken async =>
      await authInterface?.refreshToken ?? Future.value("");

  /// Removes any registered `ArcaneAuthInterface` and resets all values to
  /// default.
  Future<void> reset() async {
    _authInterface = null;
    _notifier.value = AuthenticationStatus.unauthenticated;
    _isSignedIn.value = isAuthenticated;
    _statusController.add(_notifier.value);
    _signedInController.add(_isSignedIn.value);
  }

  /// Registers an `ArcaneAuthInterface` within the `ArcaneAuthenticationService`.
  Future<void> registerInterface(ArcaneAuthInterface authInterface) async {
    if (_authInterface != null) {
      throw Exception("ArcaneAuthInterface has already been registered");
    }

    _authInterface = authInterface;
    await authInterface.init();
  }

  /// Enables the debug environment.
  ///
  /// This method does not mutate authentication status.
  Future<void> setDebug(
    BuildContext context, {
    Future<void> Function()? onDebugModeSet,
  }) async {
    final Environment previousEnvironment = Arcane.environment.environment;

    if (previousEnvironment == Environment.debug) return;

    Arcane.environment.enableDebugMode();

    if (onDebugModeSet != null) await onDebugModeSet();
  }

  /// Enables the normal environment.
  ///
  /// This method does not mutate authentication status.
  Future<void> setNormal(
    BuildContext context, {
    Future<void> Function()? onDebugModeUnset,
  }) async {
    final Environment previousEnvironment = Arcane.environment.environment;

    if (previousEnvironment == Environment.normal) return;

    Arcane.environment.disableDebugMode();

    if (onDebugModeUnset != null) await onDebugModeUnset();
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
    if (_notifier.value != newStatus) {
      _notifier.value = newStatus;
      _isSignedIn.value = isAuthenticated;
      _statusController.add(_notifier.value);
      _signedInController.add(_isSignedIn.value);
    }
  }

  @override
  void dispose() {
    unawaited(_statusStreamController?.close());
    unawaited(_signedInStreamController?.close());
    _statusStreamController = null;
    _signedInStreamController = null;
    super.dispose();
  }

  /// Logs the current user out. Upon successful logout, `status` will be set to
  /// `AuthenticationStatus.unauthenticated`.
  Future<Result<void, String>> logOut({
    Future<void> Function()? onLoggedOut,
  }) async {
    if (_authInterface == null) {
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    if (!isAuthenticated) const Result.error("User is not authenticated.");

    final Result<void, String> loggedOut = await authInterface!.logout(
      onLoggedOut: onLoggedOut,
    );

    if (loggedOut.isSuccess) {
      setUnauthenticated();
    }

    return loggedOut;
  }

  /// Logs the user in using an optional, generic `T` type of input.
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    if (_authInterface == null) {
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    final Result<void, String> result = await authInterface!.login(
      input: input,
      onLoggedIn: onLoggedIn,
    );

    if (result.isSuccess) {
      setAuthenticated();
    }

    return result;
  }

  /// Attempts to register a new account using user-defined input.
  /// Upon success, returns a `SignUpStep` indicating the next step
  /// in the signup process as a `SignUpStep`.
  Future<Result<SignUpStep, String>> register<T>({
    T? input,
  }) async {
    if (_authInterface == null) {
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    if (authInterface is! ArcaneAuthAccountRegistration) {
      return const Result.error(
        "The provided ArcaneAuthInterface does not support account registration.",
      );
    }

    final auth = authInterface as ArcaneAuthAccountRegistration;

    final Result<SignUpStep, String>? result = await auth.register(
      input: input,
    );

    if (result == null) {
      return const Result.error(
        "Registered ArcaneAuthInterface returned a null value.",
      );
    }

    return result;
  }

  /// Confirms the user's signup using their `email` and `confirmationCode`.
  /// Returns a `Result.ok(true)` if signup was successful.
  Future<Result<bool, String>> confirmSignup({
    required String email,
    required String confirmationCode,
  }) async {
    if (_authInterface == null) {
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    if (authInterface is! ArcaneAuthAccountRegistration) {
      return const Result.error(
        "The provided ArcaneAuthInterface does not support account registration.",
      );
    }

    final auth = authInterface as ArcaneAuthAccountRegistration;

    final Result<bool, String>? result = await auth.confirmSignup(
      username: email,
      confirmationCode: confirmationCode,
    );

    if (result == null) {
      return const Result.error(
        "Registered ArcaneAuthInterface returned a null value.",
      );
    }

    return result;
  }

  /// Re-sends a verification code to be used when confirming the user's
  /// registration.
  Future<Result<String, String>> resendVerificationCode(String email) async {
    if (_authInterface == null) {
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    if (authInterface is! ArcaneAuthAccountRegistration) {
      return const Result.error(
        "The provided ArcaneAuthInterface does not support account registration.",
      );
    }

    final auth = authInterface as ArcaneAuthAccountRegistration;

    final Future<Result<String, String>>? result =
        auth.resendVerificationCode(input: email);

    if (result == null) {
      return const Result.error(
        "Registered ArcaneAuthInterface returned a null value.",
      );
    }

    return result;
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
      return const Result.error("No ArcaneAuthInterface has been registered");
    }

    if (authInterface is! ArcaneAuthPasswordManagement) {
      return const Result.error(
        "The provided ArcaneAuthInterface does not support password management.",
      );
    }

    final auth = authInterface as ArcaneAuthPasswordManagement;

    final Result<bool, String>? result = await auth.resetPassword(
      email: email,
      newPassword: newPassword,
      code: confirmationCode,
    );

    if (result == null) {
      return const Result.error(
        "Registered ArcaneAuthInterface returned a null value.",
      );
    }

    return result;
  }
}
