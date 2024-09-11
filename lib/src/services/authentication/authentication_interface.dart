part of "authentication_service.dart";

/// An abstract class that defines the authentication interface.
///
/// This interface provides methods for various authentication operations, including
/// signing in, signing up, resetting passwords, and managing tokens.
abstract class ArcaneAuthInterface {
  /// Returns `true` if the user is currently signed in.
  ///
  /// This is a getter that asynchronously checks if the user has an active session.
  Future<bool> get isSignedIn;

  /// Returns the access token if available.
  ///
  /// This is used to retrieve the current session's access token for authenticated
  /// API requests. Returns `null` if the user is not signed in or the token is unavailable.
  Future<String?> get accessToken;

  /// Returns the refresh token if available.
  ///
  /// The refresh token is used to renew access tokens when they expire. Returns `null` if
  /// the user is not signed in or the token is unavailable.
  Future<String?> get refreshToken;

  /// Initializes the authentication interface.
  ///
  /// This method sets up any necessary configurations or initializations required for
  /// the authentication process. It must be called before any other methods in the interface.
  Future<void> init();

  /// Logs the user out of the session.
  ///
  /// This method terminates the current session and removes any stored tokens.
  /// Returns a `Result` that either contains a `void` on success or an error message.
  Future<Result<void, String>> logout();

  /// Logs the user in using an email address and password.
  ///
  /// This method authenticates the user with their email and password credentials.
  /// Returns a `Result` that either contains a `void` on success or an error message.
  ///
  /// Example:
  /// ```dart
  /// await authInterface.loginWithEmailAndPassword(
  ///   email: "user@example.com",
  ///   password: "password123",
  /// );
  /// ```
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Re-sends a verification code to the user's email address.
  ///
  /// This method is typically used when the user hasn't received or has lost their initial
  /// verification code. Returns a `Result` that contains the verification code on success
  /// or an error message.
  Future<Result<String, String>> resendVerificationCode(
    String email,
  );

  /// Signs a user up with a username, password, and email.
  ///
  /// This method registers a new user in the system. Returns a `Result` that contains
  /// the next [SignUpStep] in the process on success or an error message.
  ///
  /// Example:
  /// ```dart
  /// await authInterface.signup(
  ///   email: "user@example.com",
  ///   password: "password123",
  /// );
  /// ```
  Future<Result<SignUpStep, String>> signup({
    required String password,
    required String email,
  });

  /// Confirms a user's signup using a username and a confirmation code.
  ///
  /// This method completes the sign-up process by verifying the user's confirmation code.
  /// Returns a `Result` that contains `true` on success or an error message.
  Future<Result<bool, String>> confirmSignup({
    required String username,
    required String confirmationCode,
  });

  /// Resets a user's password using an email address and a code.
  ///
  /// This method is used when a user requests to reset their password. The reset code
  /// they receive via email is used to verify the request. Optionally, a new password can
  /// be provided. Returns a `Result` that contains `true` on success or an error message.
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? code,
  });
}