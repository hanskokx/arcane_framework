import "package:arcane_framework/arcane_framework.dart";

typedef Credentials = ({String email, String password});

class DebugAuthInterface
    with ArcaneAuthAccountRegistration, ArcaneAuthPasswordManagement
    implements ArcaneAuthInterface {
  DebugAuthInterface._internal();

  static final ArcaneAuthInterface _instance = DebugAuthInterface._internal();
  static ArcaneAuthInterface get I => _instance;

  @override
  Future<bool> get isSignedIn => Future.value(_isSignedIn);
  bool _isSignedIn = false;

  @override
  Future<String?> get accessToken => isSignedIn.then(
        (loggedIn) => loggedIn ? "access_token" : null,
      );

  @override
  Future<String?> get refreshToken => isSignedIn.then(
        (loggedIn) => loggedIn ? "refresh_token" : null,
      );

  @override
  Future<Result<void, String>> logout({
    Future<void> Function()? onLoggedOut,
  }) async {
    Arcane.log("Logging out");

    _isSignedIn = false;

    return const Result.ok(null);
  }

  @override
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    final bool alreadyLoggedIn = await isSignedIn;

    if (alreadyLoggedIn) return const Result.ok(null);

    final credentials = input as Credentials;

    final String email = credentials.email;
    final String password = credentials.password;

    Arcane.log("Logging in as $email using password $password");

    _isSignedIn = true;

    return const Result.ok(null);
  }

  @override
  Future<Result<String, String>> resendVerificationCode<T>({
    T? input,
  }) async {
    Arcane.log("Re-sending verification code to $input");
    return const Result.ok("Code sent");
  }

  @override
  Future<Result<SignUpStep, String>> register<T>({
    T? input,
  }) async {
    if (input != null) {
      final credentials = input as Credentials;

      final String email = credentials.email;
      final String password = credentials.password;

      Arcane.log("Creating account for $email with password $password");
    }

    return const Result.ok(SignUpStep.confirmSignUp);
  }

  @override
  Future<Result<bool, String>> confirmSignup({
    String? username,
    String? confirmationCode,
  }) async {
    Arcane.log(
      "Confirming registration for $username with code $confirmationCode",
    );
    return const Result.ok(true);
  }

  @override
  Future<Result<bool, String>> resetPassword({
    String? email,
    String? newPassword,
    String? code,
  }) async {
    Arcane.log("Resetting password for $email");
    return const Result.ok(true);
  }

  @override
  Future<void> init() async {
    Arcane.log("Debug auth interface initialized.");
    return;
  }
}
