import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// A `Cubit` that manages the application environment state.
///
/// The `ArcaneEnvironment` cubit holds the current environment (`debug` or `normal`)
/// and provides a method to enable debug mode.
class ArcaneEnvironment extends Cubit<Environment> {
  /// Initializes the cubit with the `normal` environment as the default state.
  ArcaneEnvironment() : super(Environment.normal);

  /// Enables debug mode by setting the environment to `Environment.debug`.
  void enableDebugMode() {
    if (state == Environment.debug) return;

    emit(Environment.debug);
  }

  /// Disables debug mode by setting the environment to `Environment.normal`.
  void disableDebugMode() {
    if (state == Environment.normal) return;

    emit(Environment.normal);
  }
}

/// A widget that provides `ArcaneEnvironment` to the widget tree using `BlocProvider`.
///
/// This widget wraps around a child widget and makes `ArcaneEnvironment` available
/// to the rest of the widget tree. It should be used in combination with `BlocProvider`
/// from the `flutter_bloc` package.
///
/// Example:
/// ```dart
/// ArcaneEnvironmentProvider(
///   child: MyApp(),
/// );
/// ```
class ArcaneEnvironmentProvider extends StatelessWidget {
  /// The widget that will be provided with access to the `ArcaneEnvironment`.
  final Widget child;

  /// Constructs an `ArcaneEnvironmentProvider` with the given [child].
  const ArcaneEnvironmentProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ArcaneEnvironment(),
      child: child,
    );
  }
}
