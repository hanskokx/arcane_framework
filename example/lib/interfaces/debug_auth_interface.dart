import "package:arcane_framework/arcane_framework.dart";

typedef LoginInput = ({String email, String password});

class DebugAuthInterface implements ArcaneAuthInterface {
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
  Future<Result<void, String>> logout() async {
    Arcane.log("Logging out");

    _isSignedIn = false;

    return Result.ok(null);
  }

  @override
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, String>> login<LoginInput>({
    LoginInput? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    final bool alreadyLoggedIn = await isSignedIn;

    if (alreadyLoggedIn) return Result.ok(null);

    final credentials = input as ({String email, String password});

    final String email = credentials.email;
    final String password = credentials.password;

    Arcane.log("Logging in as $email using password $password");

    _isSignedIn = true;

    return Result.ok(null);
  }

  @override
  Future<Result<String, String>> resendVerificationCode(String email) async {
    Arcane.log("Re-sending verification code to $email");
    return Result.ok("Code sent");
  }

  @override
  Future<Result<SignUpStep, String>> signup({
    required String password,
    required String email,
  }) async {
    Arcane.log("Creating account for $email with password $password");
    return Result.ok(SignUpStep.confirmSignUp);
  }

  @override
  Future<Result<bool, String>> confirmSignup({
    required String username,
    required String confirmationCode,
  }) async {
    Arcane.log(
      "Confirming registration for $username with code $confirmationCode",
    );
    return Result.ok(true);
  }

  @override
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? code,
  }) async {
    Arcane.log("Resetting password for $email");
    return Result.ok(true);
  }

  @override
  Future<void> init() async {
    Arcane.log("Debug auth interface initialized.");
    return;
  }
}
