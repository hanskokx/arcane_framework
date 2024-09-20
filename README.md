The Arcane Framework is a powerful Dart package designed to provide a robust architecture for managing key application services such as logging, authentication, secure storage, feature flags, theming, and more. This framework is ideal for building scalable applications that require dynamic configuration and service management.

## Features

- **Service Management**: Centralized access to multiple services (logging, authentication, theming, etc.).
- **Feature Flags**: Dynamically enable or disable features using `ArcaneFeatureFlags`.
- **Logging**: Easily log messages with metadata, stack traces, and different log levels via `ArcaneLogger`.
- **Authentication**: Built-in support for handling user authentication workflows.
- **Theming**: Switch between light and dark themes with `ArcaneReactiveTheme`.

## Getting Started

To use Arcane Framework in your Dart or Flutter project, follow these steps:

### Installation

 1. Add the dependency to your pubspec.yaml:

  ```yaml
  dependencies:
    arcane_framework: <latest>
  ```

  2. Wrap your `MaterialApp` or `CupertinoApp` with the `ArcaneApp` Widget, providing the necessary services and your root widget.

  ```dart
  import 'package:arcane_framework/arcane_framework.dart';

  void main() {
    runApp(
      ArcaneApp(
        services: [
          MyArcaneService.I,
        ],
        child: MyApp(...),
      ),
    );
  }
  ```

## Usage

The following sections provide more information about how to use the framework features.

### Services

The Arcane Framework provides a centralized way to manage services across your application. This allows you to easily access and configure all of your services from anywhere in your app, without having to pass them down through multiple widgets.

A service's purpose is to facilitate cross-feature communication of small pieces of data. For example, one feature may ask a user for their favorite color, while another feature may use that color to change the background of a screen. The feature ingesting the users' favorite color should not care how the favorite color has been determined, nor should it rely directly upon the feature that determines said color. A service can be used to hold the color in question, effectively decoupling these two features. One service sets the value while another ingests it.

```dart
class FavoriteColorService extends ArcaneService {
  static bool _mocked = false;
  static final FavoriteColorService _instance = FavoriteColorService._internal();

  static FavoriteColorService get I => _instance;

  FavoriteColorService._internal();

  Color? _myFavoriteColor;
  Color? get myFavoriteColor => _myFavoriteColor;

  void setMyFavoriteColor(Color? newValue) {
    if (_mocked) return;

    _myFavoriteColor = newValue;

    notifyListeners();
  }

  @visibleForTesting
  static void setMocked() => _mocked = true;
}
```

To register a service with Arcane, simply add the instance of the `ArcaneService` to your list of services when initializing the `ArcaneApp`.

```dart
ArcaneApp(
  services: [
    FavoriteColorService.I,
  ],
  child: MyApp(...),
),
```

Service properties can be accessed either directly (e.g., `FavoriteColorService.I.myFavoriteColor`) or via `BuildContext` (e.g., `context.serviceOfType<FavoriteColorService>()?.myFavoriteColor`). If the `notifyListeners()` method is included within your service, any widgets that are referencing the service property through `BuildContext` will automatically be notified of the change.

### Feature Flags

You can easily manage feature flags using the `ArcaneFeatureFlags` built-in service. Feature flags are useful for enabling or disabling different parts of your application under different circumstances. For example, you may want to enable a new feature only once it has finished development and testing, while still having the ability to ship the unfinished code. You could also leverage feature flags to enable different modes within your application (e.g., "free" vs "paid"). Furthermore, they can be used for A/B testing. The options are truly unlimited.

To get started, create an `enum` to define your features:

```dart
enum Feature {
  awesomeFeature(true),
  prettyOkFeature(false),
  ;

  /// Determines whether the given [Feature] is enabled by default when the
  /// application launches. Features can be enabled or disabled during runtime,
  /// regardless of this value.
  final bool enabledAtStartup;

  const Feature(this.enabledAtStartup);
}
```

Next, ensure that your features are enabled at startup by registering them within the feature flag service:

```dart
  void main() {
    WidgetsFlutterBinding.ensureInitialized();

    // Register your Enum that you'll be using to enable and disable features.
    for (final Feature feature in Feature.values) {
      if (feature.enabledAtStartup) Arcane.features.enableFeature(feature);
    }

    runApp(const ArcaneApp());
  }
```

When you want to determine if a feature is enabled, you can use one of the helper extensions:

```dart
// Via an enum extension
final bool isMyAwesomeFeatureEnabled = Feature.awesomeFeature.enabled;

// Via the Arcane feature flag service
final bool isMyPrettyOkFeatureDisabled = Arcane.features.isDisabled(Feature.prettyOkFeature);
```

You can also enable and disable features at runtime:

```dart
// Via an enum extension
Feature.awesomeFeature.disable();
Feature.prettyOkFeature.enable();

// Via the Arcane features service
Arcane.features.disableFeature(Feature.awesomeFeature);
Arcane.features.enableFeature(Feature.prettyOkFeature);
```

To get a list of the currently enabled features, simply ask the Arcane feature flag service:

```dart
final List<Enum> enabledFeatures = Arcane.features.enabledFeatures;
```

Note that it is possible to register multiple different `Enum` types in the feature flag service, should one have a need to do so.

### Logging

The Arcane Framework provides a robust logging system for your application. This allows you to easily log messages with metadata, stack traces, and different log levels. The framework also provides an easy way to configure the logger's behavior (e.g., whether or not to show stack traces).

To get started, first create one or more logging interfaces, extending the `LoggingInterface` base class.

```dart
class DebugConsole implements LoggingInterface {
  static final DebugConsole _instance = DebugConsole._internal();
  static DebugConsole get I => _instance;

  final bool _initialized = true;

  @override
  bool get initialized => I._initialized;

  DebugConsole._internal();

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  @override
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level,
    StackTrace? stackTrace,
  }) {
    debugPrint(
      "$message\n"
      "$metadata\n",
    );
  }

  @override
  Future<LoggingInterface?> init() async {
    if (_mocked) return null;

    return I;
  }
}
```

Next, register your logging interface with the Arcane logger service:

```dart
// Register your logging interface(s)
await Arcane.logger.registerInterfaces([
  DebugConsole.I,
]);

// Initialize registered logging interfaces
// NOTE: This step may be deferred until a user has consented to app tracking.
await Arcane.logger.initializeInterfaces();
```

Finally, add any additional persistent metadata to your log messages (optional) and log a message:

```dart
// Add metadata to the logger
Arcane.logger.addPersistentMetadata({
  "app_name": "My App",
  "environment": "production",
});

// Log a message!
Arcane.log(
  "This is a debug message",
  level: Level.debug,
  module: "ModuleName",
  method: "MethodName",
  metadata: {"key": "value"},
  stackTrace: StackTrace.current,
);
```

Multiple logging interfaces can be registered simultaneously.

**Important**: Logging interfaces should generally be initialized after being registered with the logger service. This ensures that all logging interfaces are properly initialized before any messages are logged. This should typically be done manually in order to properly present the user with a message stating that they're about to be prompted for tracking permissions (on iOS).

### Authentication

The Arcane Framework provides a useful interface for performing common authentication tasks, such as registration, password resets, login, log out, and enabling a debug mode.

To get started, create an authentication interface provider and register it in the Arcane authentication module:

```dart
typedef LoginInput = ({String email, String password});

// Create an authentication interface
class AuthProviderInterface implements ArcaneAuthInterface {
  AuthProviderInterface._internal();

  static bool _mocked = false;

  static final AuthProviderInterface _instance = AuthProviderInterface._internal();
  static AuthProviderInterface get I => _instance;

  Future<AuthSession?> get _session async {
    return await ThirdPartyAuthProvider.fetchAuthSession();
  }

  @override
  Future<bool> get isSignedIn =>
      _session.then((value) => value?.isSignedIn == true);

  @override
  Future<String?> get accessToken => isSignedIn.then(
        (loggedIn) => loggedIn
            ? _session.then(
                (value) => value?.accessToken,
              )
            : null,
      );

  @override
  Future<String?> get refreshToken => isSignedIn.then(
        (loggedIn) => loggedIn
            ? _session.then(
                (value) => value?.refreshToken,
              )
            : null,
      );

  @override
  Future<Result<void, String>> logout() async {
    final result = await _session.signOut();

    if (result is FailedSignOut) {
      return Result.error(result.exception.message);
    }

    return Result.ok(null);
  }

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

    try {
      final SignInResult result = await _session.signIn(
        username: email,
        password: password,
      );
      return Result.ok(null);
    } on AuthException catch (e) {
      return Result.error("Error signing in: ${e.message}");
    } catch (e) {
      return Result.error("Error signing in: $e");
    }
  }

  @override
  Future<Result<String, String>> resendVerificationCode(String email) async {
    try {
      final result = await _session.resendSignUpCode(username: email);
      return Result.ok(result.message);
    } catch (e) {
      return Result.error("Error resending verification code: ${e.message}");
    }
  }

  @override
  Future<Result<SignUpStep, String>> signup({
    required String password,
    required String email,
  }) async {
    try {
      final SignUpResult result = await _session.signUp(
        username: email,
        password: password,
      );

      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        return Result.ok(SignUpStep.confirmSignUp);
      }

      return Result.ok(SignUpStep.done);
    } catch (e) {
      return Result.error("Error signing up user: ${e.message}");
    }
  }

  @override
  Future<Result<bool, String>> confirmSignup({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      final SignUpResult result = await _session.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );

      return Result.ok(result.isSignUpComplete);
    } on AuthException catch (e) {
      return Result.error("Error confirming user: ${e.message}");
    }
  }

  @override
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? code,
  }) async {
    try {
      late ResetPasswordResult result;
      if (newPassword != null && code != null) {
        result = await _session.confirmResetPassword(
          username: email,
          newPassword: newPassword,
          confirmationCode: code,
        );
      }

      if (newPassword == null && code == null) {
        result = await _session.resetPassword(
          username: email,
        );
      }

      return Result.ok(result.isPasswordReset);
    } catch (e) {
      return Result.error("Error resetting the password: ${e.message}");
    }
  }

  @override
  Future<void> init() async {
    if (_mocked) return;

    if (ThirdPartyAuthProvider.isConfigured) return;

    await ThirdPartyAuthProvider.initialize();
  }

  @visibleForTesting
  static void setMocked() {
    _mocked = true;
  }
}


// Register an interface to handle user authentication.
await Arcane.auth.registerInterface(AuthProviderInterface.I);
```

Once your interface has been created and registered, you can use it to perform a number of common authentication tasks:

```dart
// Register an account
final nextStep = await Arcane.auth.signup(
  email: "user@example.com",
  password: "password123",
);

// Confirm a newly registered account
final accountConfirmed = await Arcane.auth.confirmSignup(
  email: "user@example.com",
  confirmationCode: "123456",
);

// Re-send a verification code
final response = await Arcane.auth.resendVerificationCode("user@example.com");

// Initiate a password reset flow
final passwordResetStarted = await Arcane.auth.resetPassword(
  email: "user@example.com",
  newPassword: "password456",
);

// Confirm password reset
final passwordResetFinished = await Arcane.auth.resetPassword(
  email: "user@example.com",
  newPassword: "password456",
  confirmationCode: "123456",
);

// Sign in with email and password
final result = await Arcane.auth.login(
  input: ("email": "user@example.com", "password": "password123")
  onLoggedIn: () => Arcane.log("User logged in"),
);

// Sign out
await Arcane.auth.logout();

// Set the system to debug mode
await Arcane.auth.setDebug();
```

### Dynamic Theming

The Arcane Framework provides a simple interface for managing themes in your application, with dynamic switching between dark and light themes based on the user's system settings, or manually switching between themes.

To get started, first register your `ThemeData` objects with the Arcane theme module:

```dart
void main() {
  // Set your Themes
  Arcane.theme
    ..setDarkTheme(darkTheme)
    ..setLightTheme(lightTheme);

  runApp(
    ArcaneApp(
      child: MainApp(),
    ),
  );
}
```

From here, you can either follow the system theme:

```dart
// Follow the system's theme mode
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return ArcaneApp(
      child: MaterialApp(
        theme: Arcane.theme.light,
        darkTheme: Arcane.theme.dark,
        themeMode: Arcane.theme.systemTheme.value,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    Arcane.theme.followSystemTheme(context);
    super.didChangeDependencies();
  }
}
```

or manually control the theme mode:

```dart
// Manually control the theme mode
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaneApp(
      child: MaterialApp(
        theme: Arcane.theme.light,
        darkTheme: Arcane.theme.dark,
        themeMode: Arcane.theme.currentMode,
      ),
    );
  }
}
```

Then, you can switch modes whenever you want:

```dart
// Switch between light and dark themes
Arcane.theme.switchTheme();

// Access current theme data
final ThemeData currentTheme = Arcane.theme.currentMode == ThemeMode.dark
  ? Arcane.theme.dark
  : Arcane.theme.light;

if (context.isDarkMode) {
  // Do something when dark mode is active
}

// Set a custom dark theme
Arcane.theme.setDarkTheme(customDarkTheme);

// Set a custom light theme
Arcane.theme.setLightTheme(customLightTheme);
```

## Contributing

We welcome contributions to the Arcane Framework. If you’d like to contribute, please:

  1. Fork the repository.
  2. Create a new feature branch.
  3. Submit a pull request with a description of your changes.

For detailed information on how to contribute, please refer to CONTRIBUTING.md.
