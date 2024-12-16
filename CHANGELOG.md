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
