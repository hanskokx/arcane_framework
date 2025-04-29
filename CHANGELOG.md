## 2.0.0

### Arcane

- [FIX] The `Arcane` class is now `abstract`

### ArcaneEnvironment

- [CHANGE] The dependency on `flutter_bloc` has been removed.
- [CHANGE] The feature has been completely rewritten as an inherited widget, rather than using a `Cubit`.
- [NEW] The `ArcaneEnvironment` widget now includes the `maybeOf(context)` and `of(context)` service locators.
- [NEW] An `ArcaneEnvironmentProvider` widget has been added. This is used by `ArcaneApp` but can also be used independently when not using the `ArcaneApp` widget.
- [BREAKING] The locator for `ArcaneEnvironment` has been changed from `context.read<ArcaneEnvironment>()` to `ArcaneEnvironment.of(context)`
- [BREAKING] Reading the current environment has been changed from `context.read<ArcaneEnvironment>().state` to `ArcaneEnvironment.of(context).environment`;

### ArcaneServiceProvider

- [NEW] Added a new `ArcaneServiceProvider.maybeOf(context)` getter which returns a nullable `ArcaneServiceProvider` instance.
- [NEW] `ArcaneServiceProvider` now includes a `serviceOfType<T>(context)` getter to retrieve a nullable registered service instance.
- [NEW] An `addService` method was added to `ArcaneServiceProvider`
- [NEW] A `setServices` method was added to `ArcaneServiceProvider`. Invoking this method with a list of `ArcaneService` instances will replace all existing services in the `ArcaneServiceProvider`.
- [DEPRECATED] `context.serviceOfType<T>` has been deprecated in favor of `context.service<T>`.
- [NEW] `context.requiredService<T>` has been added to provide a mechanism for ensuring a particular service has been registered.
- [NEW] `ArcaneService<T>.of(context)` has been added for easy access to service instances. It returns a nullable service instance.
- [NEW] `ArcaneService<T>.requiredOf(context)` has been added. It returns a non-nullable service instance, and throws an exception if the service instance has not been registered.

### Authentication Service (ArcaneAuth)

- [FIX] Switching between `Environment.normal` and `Environment.debug` now correctly notifies subscribers
- [BREAKING] Switching between environments now remembers the previous authentication status (e.g., switching to debug mode and then back to normal mode will now remember whether you were authenticated or unauthenticated in normal mode when you switched to debug mode.)

### Feature Flags Service (ArcaneFeatureFlags)

- [NEW] A `reset` method has been added, which will remove all enabled features and de-initialize the service.

### Logging Service (ArcaneLogger)

- [NEW] A `logStream` has been added. This will stream all log messages that are sent to `ArcaneLogger`. These messages are not processed by any registered `LoggingInterface`.
- [BREAKING] Invoking the `log` method no longer throws an exception if `ArcaneLogger` has not been initialized. Log messages will always be sent to the `logStream` and will only be sent to the registered `LoggingInterface`s if the `init` method has ben invoked.
- [FIX] Automatic file and line number detection has been improved, both in terms of performance and in reliability.
- [NEW] In addition to the existing `registerInterfaces` method, a new `registerInterface` method has been added.
- [NEW] The following methods have been added: `unregisterInterface`, `unregisterInterfaces`, and `unregisterAllInterfaces`.
- [NEW] Added a `reset` method that clears all registered interfaces, clears all persistent metadata, and de-initializes `ArcaneLogger`
- [BREAKING] Added a `skipAutodetection` option (defaults to `false`) when invoking the `log` method. When set to `true`, automatic file and line number detection, as well as automatic module and method detection will not be performed (the module and method can still be added as properties). Skipping autodetection may help to increase performance, as a `StackTrace` is no longer generated and parsed. This property will need to be added to existing `LoggingInterface` implementations.

### Theme (ArcaneTheme)

- [NEW] Added `themeMode` extension to `BuildContext` to get the current `ThemeMode` (e.g., light/dark)
- [BREAKING] Completely rewrote `ArcaneReactiveTheme`
- [NEW] Added the `ArcaneThemeSwitcher` widget

#### ArcaneReactiveTheme

- [NEW] The `isFollowingSystemTheme` getter has been added.
- [NEW] The `themeModeChanges` getter will stream events when the `ThemeMode` changes (e.g., light/dark)
- [NEW] The `themeDataChanges` getter will stream events when the current `ThemeData` changes
- [NEW] The `systemThemeMode` getter will return the OS-level brightness (e.g., light/dark)
- [BREAKING] The `currentMode` getter was renamed to `currentThemeMode`
- [NEW] The `currentTheme` getter was added to retrieve the current `ThemeData`.
- [BREAKING] The `systemTheme` getter was replaced by the `systemThemeMode` getter
- [NEW] A `currentModeOf(context)` getter was added. Using this value will trigger a rebuild when the mode changes.
- [CHANGE] The `switchTheme` method now (optionally) takes in a `ThemeMode` parameter. If it is omitted, the new mode will be automatically determined.
- [FIX] The `followSystemTheme` method will now correctly trigger widget rebuilds under the correct circumstances.
- [FIX] Invoking the `setDarkTheme` and `setLightTheme` methods will trigger widget rebuilds under the correct circumstances.
- [BREAKING] In order to enable following the system brightness changes, the `Arcane.theme.followSystemTheme(context)`/`ArcaneReactiveTheme.I.followSystemTheme(context)` method will need to be invoked once.
- [NEW] When manually switching from following the system theme to a specific theme (e.g., `switchTheme()`), the system theme will no longer be followed. To follow the system theme once again, the `followSystemTheme(context)` method should be invoked.

#### ArcaneThemeSwitcher

- [NEW] This new widget will, when added to the widget tree, trigger rebuilds when the theme mode or theme style is updated via `ArcaneTheme`/`ArcaneReactiveTheme`.
- [NEW] This widget has been added to `ArcaneApp`.

### Testing

- [NEW] Tests have been written for much of the framework.

### Example

- [FIX] The example has been completely reworked. It now includes examples of all features that Arcane has to offer.

### Misc

- [FIX] Dartdoc comments have been added throughout the framework where they were previously missing.

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
