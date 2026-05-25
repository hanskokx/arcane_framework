part of "authentication_service.dart";

/// An enum representing the different steps in the sign-up process.
///
/// This enum has two possible values:
/// - `confirmSignUp`: The user needs to confirm the sign-up process.
/// - `done`: The sign-up process is complete.
///
/// Example:
/// ```dart
/// SignUpStep step = SignUpStep.confirmSignUp;
/// if (step == SignUpStep.done) {
///   // Sign-up process is finished
/// }
/// ```
enum SignUpStep {
  /// The step where the user needs to confirm their sign-up,
  /// typically through email or other verification methods.
  confirmSignUp,

  /// The sign-up process is complete.
  done,
}

/// An enum representing the authentication status of a user.
///
/// This enum has two possible states:
/// - `authenticated`: The user is authenticated.
/// - `unauthenticated`: The user is not authenticated.
///
/// Example:
/// ```dart
/// AuthenticationStatus status = AuthenticationStatus.authenticated;
/// if (status.isAuthenticated) {
///   // User is authenticated
/// }
/// ```
enum AuthenticationStatus {
  /// The user is authenticated.
  authenticated,

  /// The user is not authenticated.
  unauthenticated;

  /// Returns `true` if the current status is `authenticated`.
  bool get isAuthenticated => this == authenticated;

  /// Returns `true` if the current status is `unauthenticated`.
  bool get isUnauthenticated => this == unauthenticated;
}
