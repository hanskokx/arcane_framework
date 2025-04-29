/// The Arcane Framework is a comprehensive Dart package designed to provide a
/// scalable architecture for managing essential application services such as
/// logging, authentication, theming, feature flags, and more.
///
/// The framework offers a centralized way to access and manage these services,
/// making it easy to build dynamic and feature-rich applications. It includes
/// a robust logging system, dynamic feature toggles, theming capabilities, and
/// user authentication handling.
///
/// ## Key Features:
/// - **Service Management**: Centralized access to critical services like
///   logging, feature flags, and theming.
/// - **Feature Flags**: Dynamically enable or disable features using
///   `ArcaneFeatureFlags`.
/// - **Logging**: Flexible logging with different severity levels
///   (`debug`, `info`, `error`, etc.).
/// - **Theming**: Easy light/dark mode switching with `ArcaneReactiveTheme`.
/// - **Authentication**: Manage user login, sign up, and token-based
///   authentication.
///
/// Example usage:
/// ```dart
/// import 'package:arcane_framework/arcane_framework.dart';
///
/// void main() {
///   runApp(
///     ArcaneApp(
///       services: [MyArcaneService.I],
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// This library is designed to simplify the development of complex, scalable
/// Flutter applications by offering a set of tools to manage core
/// functionalities efficiently.
library;

export "package:arcane_framework/src/arcane.dart";
export "package:arcane_framework/src/arcane_app.dart";
export "package:arcane_framework/src/providers/environment_provider.dart";
export "package:arcane_framework/src/providers/service/arcane_service.dart";
export "package:arcane_framework/src/services/authentication/authentication_service.dart";
export "package:arcane_framework/src/services/feature_flags/feature_flags_service.dart";
export "package:arcane_framework/src/services/logging/logging_service.dart";
export "package:arcane_framework/src/services/reactive_theme/reactive_theme_service.dart";
export "package:arcane_framework/src/services/reactive_theme/reactive_theme_switcher.dart";
export "package:result_monad/result_monad.dart";
