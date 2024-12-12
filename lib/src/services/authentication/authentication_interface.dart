part of "authentication_service.dart";

/// An abstract class that defines the authentication interface.
///
/// This interface provides methods for various authentication operations,
/// including signing in, signing up, resetting passwords, and managing tokens.
abstract class ArcaneAuthInterface {
  /// Returns `true` if the user is currently signed in.
  ///
  /// This is a getter that asynchronously checks if the user has an active
  /// session.
  Future<bool> get isSignedIn;

  /// Returns the access token if available.
  ///
  /// This is used to retrieve the current session's access token for
  /// authenticated API requests. Returns `null` if the user is not signed in or
  /// the token is unavailable.
  Future<String?>? get accessToken;

  /// Returns the refresh token if available.
  ///
  /// The refresh token is used to renew access tokens when they expire. Returns
  /// `null` if the user is not signed in or the token is unavailable.
  Future<String?>? get refreshToken;

  /// Initializes the authentication interface.
  ///
  /// This method sets up any necessary configurations or initializations
  /// required for the authentication process. It must be called before any
  /// other methods in the interface.
  Future<void> init() => Future.value(null);

  /// Logs the user out of the session.
  ///
  /// This method terminates the current session and removes any stored tokens.
  /// Returns a `Result` that either contains a `void` on success or an error
  /// message.
  Future<Result<void, String>> logout();

  /// Logs the user in using an optional, generic `T` type of input.
  /// This login method is a generic method that can be used to login with any
  /// type of input. It is useful for login methods that do not require an email
  /// and password. Any type of input can be passed in, and it will be handled
  /// by the implementation of the method wihin the specific authentication
  /// service.
  ///
  /// Example:
  /// ```dart
  /// await authInterface.login<Map<String, String>>(
  ///   input: {
  ///     "username": "hello@world.com",
  ///     "password": "password",
  ///   },
  /// );
  /// ```
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  });
}

/// Provides methods related to account registration and verification.
///
/// This mixin is intended to be used as part of an authentication system
/// where account registration and email verification are required.
mixin ArcaneAuthAccountRegistration {
  /// Re-sends a verification code to the user's email address.
  ///
  /// This method is typically used when the user hasn't received or has lost
  /// their initial verification code. Returns a [Result] containing the
  /// verification code on success or an error message.
  ///
  /// - [T]: The type of input passed to the method. This can be used for custom
  ///   input structures.
  ///
  /// Example:
  /// ```dart
  /// final result = await auth.resendVerificationCode(input: {"email": "user@example.com"});
  /// ```
  Future<Result<String, String>>? resendVerificationCode<T>({T? input});

  /// Registers a new account using user-supplied input.
  ///
  /// This method adds a new user to the system. Returns a [Result] containing
  /// the next [SignUpStep] in the registration process on success or an error
  /// message.
  ///
  /// - [T]: The type of input passed to the method. This can be used for custom
  ///   input structures.
  ///
  /// Example:
  /// ```dart
  /// final result = await auth.register(input: {
  ///   "email": "user@example.com",
  ///   "password": "password123"
  /// });
  /// ```
  Future<Result<SignUpStep, String>>? register<T>({T? input});

  /// Confirms a user's signup using a username and a confirmation code.
  ///
  /// This method finalizes the account registration process by validating the
  /// confirmation code sent to the user. Returns a [Result] containing `true`
  /// on success or an error message.
  ///
  /// Parameters:
  /// - [username]: The username of the account being confirmed.
  /// - [confirmationCode]: The code sent to the user's email address for
  ///   verification.
  ///
  /// Example:
  /// ```dart
  /// final result = await auth.confirmSignup(
  ///   username: "user@example.com",
  ///   confirmationCode: "123456"
  /// );
  /// ```
  Future<Result<bool, String>>? confirmSignup({
    String? username,
    String? confirmationCode,
  });
}

/// Provides methods for managing user passwords.
///
/// This mixin includes functionality for resetting passwords and handling
/// password reset codes or pins as part of an authentication system.
mixin ArcaneAuthPasswordManagement {
  /// Resets a user's password using an email address and a code.
  ///
  /// This method is used when a user requests to reset their password. The
  /// reset code they receive via email is used to verify the request.
  /// Optionally, a new password can be provided. Returns a [Result] containing
  /// `true` on success or an error message.
  ///
  /// This method may be called in two steps:
  /// 1. Provide the `email` to trigger a password reset email. This email will
  ///    contain a reset code or pin for verification.
  /// 2. Provide the `email`, the `newPassword`, and the `code` received in the
  ///    email to finalize the password reset process.
  ///
  /// Parameters:
  /// - [email]: The email address associated with the user account.
  /// - [newPassword]: The new password to set for the user. Required in the
  ///   second step.
  /// - [code]: The password reset code sent to the user's email. Required in
  ///   the second step.
  ///
  /// Example:
  /// ```dart
  /// // Step 1: Trigger reset email
  /// final step1 = await auth.resetPassword(email: "user@example.com");
  ///
  /// // Step 2: Complete reset
  /// final step2 = await auth.resetPassword(
  ///   email: "user@example.com",
  ///   newPassword: "newPassword123",
  ///   code: "123456"
  /// );
  /// ```
  Future<Result<bool, String>>? resetPassword({
    String? email,
    String? newPassword,
    String? code,
  });
}
