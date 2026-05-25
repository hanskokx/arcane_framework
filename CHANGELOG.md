## Unreleased

### Arcane Framework

- [NEW] `ArcaneApp` now owns and publishes a live service registry for
  provider-aware static lookups.
- [CHANGE] `Arcane.features`, `Arcane.auth`, `Arcane.theme`, and
  `Arcane.environment` now prefer the live `ArcaneApp` registry instance when
  available, then fall back to built-in singletons.

### Environment Service

- [NEW] Added `ArcaneEnvironmentService` as a singleton `ArcaneService` instance.
- [CHANGE] Changed `ArcaneEnvironment` is no longer a `Cubit` and is now an
  `InheritedWidget`.
- [NEW] Added `Arcane.environment` shortcut for direct environment access.
- [NEW] Added environment service to `Arcane.services` built-in list.
- [CHANGE] `ArcaneEnvironmentProvider` is now a `StatefulWidget`.
- [NEW] `ArcaneEnvironmentProvider` now provides methods for
  `enableDebugMode()`, `disableDebugMode()` and `setEnvironment()`.

### Authentication Service

- [NEW] Added `statusChanges` stream to observe `AuthenticationStatus` updates.
- [NEW] Added `signedInChanges` stream to observe sign-in state changes.
- [FIX] Added stream lifecycle cleanup in `dispose` with safe lazy recreation.

### Feature Flag Service

- [CHANGE] Renamed service class `ArcaneFeatureFlags` to
  `ArcaneFeatureFlagService`.
- [NEW] Added backward compatibility typedef:
  `typedef ArcaneFeatureFlags = ArcaneFeatureFlagService`.
- [NEW] Added `enabledFeaturesChanges` stream to observe enabled feature
  updates in realtime.
- [FIX] Added stream lifecycle cleanup in `dispose` with safe lazy recreation.
- [NEW] Added `ArcaneFeatureFlagProvider` (`InheritedWidget`) and
  `ArcaneFeatureFlagsProvider` (`StatefulWidget`) for first-class feature-flag
  integration in the widget tree.
- [NEW] Added `BuildContext` convenience accessors for feature flags, including
  `context.featureFlags`, `context.maybeFeatureFlags`,
  `context.isFeatureEnabled(...)`, and `context.isFeatureDisabled(...)`.
- [NEW] `ArcaneApp` now includes `ArcaneFeatureFlagsProvider` by default,
  enabling rebuilds for widgets that depend on
  `ArcaneFeatureFlagProvider.of(context)`.
- [UPDATE] README now documents `ArcaneFeatureFlagProvider` and `ArcaneApp`
  provider composition.
- [UPDATE] Example app now demonstrates feature toggling via
  `ArcaneFeatureFlagProvider` to highlight scope-based rebuilds.

### Theme Service

- [CHANGE] Renamed `ArcaneReactiveTheme` to `ArcaneThemeService` for clearer
  naming.
- [NEW] Added backward compatibility typedef:
  `typedef ArcaneReactiveTheme = ArcaneThemeService`.
- [FIX] Theme initialization now respects `ThemeMode.system` and initializes
  `ThemeData` using the effective brightness.
- [FIX] `ArcaneThemeSwitcher` now initializes theme state once via
  `setInitialTheme(context)`.
- [FIX] `switchTheme()` now toggles from the effective theme when current mode
  is `ThemeMode.system` (system dark -> light, system light -> dark).
- [CHANGE] `context.isDarkMode` now reflects effective app theme brightness
  (`Theme.of(context).brightness`) instead of raw platform brightness.
- [FIX] `followSystemTheme()` now reads platform brightness directly to avoid
  coupling system-follow behavior to app theme overrides.
- [NEW] Added assignment-style theme setters: `Arcane.theme.dark = ...` and
  `Arcane.theme.light = ...` (in addition to `setDarkTheme` /
  `setLightTheme`).
- [FIX] Reactive theme stream controllers now close only during service dispose,
  preventing stream shutdown when a single subscriber cancels.
- [UPDATE] README now documents `ArcaneThemeService` naming.

### Arcane Logger

- [NEW] Added `logStream` for realtime log subscriptions.
- [NEW] Added explicit `dispose` cleanup for logger stream resources.
- [BREAKING] `LoggingInterface` no longer includes built-in singleton-style
  initialization state.
- [NEW] Added optional lifecycle capability via `LoggingInitializable` and
  `LoggingInitializationMixin`.
- [NEW] Added optional `feature` tag to `LoggingInterface` via constructor.
- [CHANGE] `initializeInterfaces()` now initializes only interfaces that
  implement `LoggingInitializable`; other interfaces are skipped.
- [NEW] Added a `skipAutodetection` parameter to `Arcane.log` (defaults to
  `false`) that, when enabled, skips detection of the `module`, `method`, and
  file/line number where logs originated from.
- [NEW] Added the `LogInterceptor` class which can (optionally) be added to
  `ArcaneLogger` to pre-process log messages before they are sent to the
  registered `ArcaneLoggingInterface`(s).

#### Migration Steps (LoggingInterface)

1. Remove `initialized` and `init` from interfaces that do not require startup
  work.
2. If an interface requires startup/lifecycle management, add
  `LoggingInitializationMixin` (or implement `LoggingInitializable`) and move
  setup logic into `init()`.
3. Update `log(...)` implementations to guard behavior with `initialized` only
  for interfaces that opted into initialization.
4. Run tests to verify interface registration and logging behavior still match
  expectations.

Before:

```dart
class DebugConsole implements LoggingInterface {
  @override
  bool get initialized => true;

  @override
  Future<LoggingInterface?> init() async => this;

  @override
  void log(String message, {Map<String, Object?>? metadata, Level? level}) {}
}
```

After:

```dart
class DebugConsole extends LoggingInterface {
  @override
  void log(String message, {Map<String, Object?>? metadata, Level? level}) {}
}
```

- For SDK-backed loggers, opt into initialization with the mixin.

```dart
class ExternalLogger extends LoggingInterface with LoggingInitializationMixin {
  @override
  Future<void> init() async {
    if (initialized) return;
    // Start SDK.
    await super.init();
  }

  @override
  void log(String message, {Map<String, Object?>? metadata, Level? level}) {
    if (!initialized) return;
    // Send to SDK.
  }
}
```

- If desired, adopt `feature` for destination-aware filtering in interceptors.

## 1.2.5

- Improved automatic metadata detection in `ArcaneLogger`

## 1.2.4

- Update package dependencies

## 1.2.3

- Added `ValueNotifier`s to both the `ArcaneAuthenticationService` and
  `ArcaneFeatureFlags`. This enables the possibility of listening for changes to
  either service.

### Example

```dart
// Listen to changes in the authentication status
Arcane.auth.isSignedIn.addListener(() {
  if (Arcane.auth.isSignedIn.value) {
    Arcane.log("User is signed in");
  } else {
    Arcane.log("User is signed out");
  }
});

// Listen to changes in the enabled/disabled features
Arcane.features.notifier.addListener(() {
  Arcane.log("Enabled features have been updated: ${Arcane.features.notifier.value}");
});
```

## 1.2.2

- Lowered minimum required collection dependency version to prevent forcing
  users into the latest Flutter release

## 1.2.1

- Lowered minimum required SDK version to prevent forcing users into the latest
  Flutter release

## 1.2.0

- Removed flutter_secure_storage dependency as it was unused

### Breaking Changes

The following methods have been moved outside of the ArcaneAuthInterface base
class:

- resendVerificationCode
- register
- confirmSignup
- resetPassword

These methods have been moved to mixin classes. To continue using them, please
update your ArcaneAuthInterface implementations.

- To use `resendVerificationCode`, `register` and `confirmSignup`, use the new
  `ArcaneAuthAccountRegistration` mixin.
- To use `resetPassword`, use the new `ArcaneAuthPasswordManagement` mixin.

### Migration

In order to migrate your existing interfaces, update them from:

```dart
class MyAuthInterface implements ArcaneAuthInterface {}
```

to:

```dart
class MyAuthInterface
    with ArcaneAuthAccountRegistration, ArcaneAuthPasswordManagement
    implements ArcaneAuthInterface {}
```

If the methods that these mixins provide are not being used, the mixins can
safely be omitted. If only one of these mixins is required, the other can be
safely omitted.

This change should result in fewer lines of code for interface implementations
that do not require these additional features.

## 1.1.7

- Fixed an issue with the `ArcaneAuthenticationService` where an exception would
  be thrown when attempting to access an authentication token while no
  `ArcaneAuthInterface` was registered.

## 1.1.6

- Updated logging feature to indicate the feature which was enabled or disabled
  within the log message, instead of only in the metadata.

## 1.1.5

- Update package dependencies. No code changes.

## 1.1.4

- Update package dependencies. No code changes.

## 1.1.3

- Arcane Auth no longer throws exceptions when log out fails, instead returning
  a `Result<void, String>`. This behavior matches the login method.

## 1.1.2

- Removed Flutter exception handling from `ArcaneLoggingService`, as this
  functionality should be defined by a users' interface.

### Migration

Add the following to your `ArcaneLoggingInterface`'s `init` method to replicate
the previous behavior:

```dart
// Handles unhandled Flutter errors by logging them.
FlutterError.onError = (errorDetails) {
  Arcane.log(
    errorDetails.exceptionAsString(),
    level: Level.error,
    module: errorDetails.library,
    stackTrace: errorDetails.stack,
  );
};

// Handles unhandled platform-specific errors by logging them.
PlatformDispatcher.instance.onError = (error, stack) {
  Arcane.log(
    "$error",
    level: Level.error,
    stackTrace: stack,
  );
  return false;
};
```

## 1.1.1+2

- Updated example in README

## 1.1.1+1

- Updated example in README

## 1.1.1

- [BREAKING] Updated ArcaneAuthInterface to make the `resendVerificationCode`,
  `confirmSignup`, and `resetPassword` methods more versatile

Migration:

| Class               | Migration path                                                                                                                            |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| ArcaneAuthInterface | `resendVerificationCode(String email)` -> `resendVerificationCode<T>({T? input})`                                                         |
| ArcaneAuthInterface | `confirmSignup({String email, String password})` -> `confirmSignup({String? email, String? password})`                                    |
| ArcaneAuthInterface | `resetPassword({String email, String? newPassword, String? code})` -> `resetPassword({String? email, String? newPassword, String? code})` |

## 1.1.0

- [BREAKING] Updated the authentication service and interface to be more
  versatile

Migration:

| Class               | Migration path                                                                         |
| ------------------- | -------------------------------------------------------------------------------------- |
| ArcaneAuthInterface | `loginWtihEmailAndPassword({String email, String password})` -> `login<T>({T? input})` |
| ArcaneAuthInterface | `signup({String email, String password})` -> `register<T>({T? input})`                 |

## 1.0.8

- Added the `extra` parameter to the `Arcane.log` shortcut method

## 1.0.7

- Added the `extra` parameter to the `LoggingInterface`

## 1.0.6+1

- Migrated linting rules to new
  [arcane_analysis](https://pub.dev/packages/arcane_analysis) package.

## 1.0.6

- Removed get_it as a dependency

## 1.0.5+2

- Updated README and example project documentation

## 1.0.5+1

- Marked the `loginWithEmailAndPassword` method in `ArcaneAuthenticationService`
  as deprecated and updated example project

## 1.0.5

- Added the ability to use a generic type for the login method in
  ArcaneAuthenticationService
- Added the ability to reset the ArcaneAuthenticationService, which will
  unregister the current interface and clear the authentication state
- Removed unused testing tooling (e.g., `@visibleForTesting`) from the codebase
  - Migration guide: Remove usages of `setMocked` in your tests

## 1.0.4

- Resolved an issue with authentication using the ArcaneAuthenticationService
  when logging in with an email and password

## 1.0.3+1

- Added example project

## 1.0.3

- Added the ability to switch back to the normal environment from the debug
  environment in ArcaneEnvironment
- (breaking) Made the optional `onLoggedOut` callback a Future instead of a void
  function in ArcaneAuthenticationService
- Added additional error handling to the login method in
  ArcaneAuthenticationService
- Added support for following the system's theme in ArcaneTheme
- Removed the BuildContext parameter from the `switchTheme` method in
  ArcaneTheme

## 1.0.2

- Migrated ArcaneAuthenticationService's isSignedIn to a ValueListenable

## 1.0.1+1

- Removed ID and secure storage services to improve platform compatibility

## 1.0.0

- Initial release
