## 1.1.0

- [BREAKING] Updated the authentication service and interface to be more versatile

### Migration

| Class               | Migration path                                                                         |
| ------------------- | -------------------------------------------------------------------------------------- |
| ArcaneAuthInterface | `loginWtihEmailAndPassword({String email, String password})` -> `login<T>({T? input})` |
| ArcaneAuthInterface | `signup({String email, String password})` -> `register<T>({T? input})`                 |

## 1.0.8

- Added the `extra` parameter to the `Arcane.log` shortcut method

## 1.0.7

- Added the `extra` parameter to the `LoggingInterface`

## 1.0.6+1

- Migrated linting rules to new [arcane_analysis](https://pub.dev/packages/arcane_analysis) package.

## 1.0.6

- Removed get_it as a dependency

## 1.0.5+2

- Updated README and example project documentation

## 1.0.5+1

- Marked the `loginWithEmailAndPassword` method in ArcaneAuthenticationService as deprecated and updated example project

## 1.0.5

- Added the ability to use a generic type for the login method in ArcaneAuthenticationService
- Added the ability to reset the ArcaneAuthenticationService, which will unregister the current interface and clear the authentication state
- Removed unused testing tooling (e.g., `@visibleForTesting`) from the codebase
  - Migration guide: Remove usages of `setMocked` in your tests

## 1.0.4

- Resolved an issue with authentication using the ArcaneAuthenticationService when logging in with an email and password

## 1.0.3+1

- Added example project

## 1.0.3

- Added the ability to switch back to the normal environment from the debug environment in ArcaneEnvironment
- (breaking) Made the optional `onLoggedOut` callback a Future instead of a void function in ArcaneAuthenticationService
- Added additional error handling to the login method in ArcaneAuthenticationService
- Added support for following the system's theme in ArcaneTheme
- Removed the BuildContext parameter from the `switchTheme` method in ArcaneTheme

## 1.0.2

- Migrated ArcaneAuthenticationService's isSignedIn to a ValueListenable

## 1.0.1+1

- Removed ID and secure storage services to improve platform compatibility

## 1.0.0

- Initial release
