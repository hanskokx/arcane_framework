import "package:arcane_framework/src/arcane.dart";
import "package:flutter/widgets.dart";

import "environment_interface.dart";

/// Typed API for mutating environment mode from provider state.
abstract interface class ArcaneEnvironmentModeController {
  /// Enables debug mode by setting the environment to `Environment.debug`.
  void enableDebugMode();

  /// Disables debug mode by setting the environment to `Environment.normal`.
  void disableDebugMode();

  /// Sets the current environment.
  void setEnvironment(Environment environment);
}

/// An `InheritedWidget` that provides access to the application environment.
///
/// The `ArcaneEnvironment` widget holds the current environment and allows
/// descendant widgets to access and mutate it.
class ArcaneEnvironment extends InheritedWidget {
  /// Returns the current environment (alias for [environment]) for API consistency.
  Environment get current => environment;

  /// The current application environment.
  final Environment environment;

  final ValueChanged<Environment> _switchEnvironment;

  /// Creates an `ArcaneEnvironment` widget.
  const ArcaneEnvironment({
    required this.environment,
    required void Function(Environment) switchEnvironment,
    required super.child,
    super.key,
  }) : _switchEnvironment = switchEnvironment;

  /// Retrieves the `ArcaneEnvironment` instance from the nearest ancestor.
  ///
  /// Returns `null` if no `ArcaneEnvironment` ancestor is found.
  static ArcaneEnvironment? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneEnvironment>();
  }

  /// Retrieves the `ArcaneEnvironment` instance from the nearest ancestor.
  ///
  /// Throws a `StateError` if no `ArcaneEnvironment` ancestor is found.
  static ArcaneEnvironment of(BuildContext context) {
    final ArcaneEnvironment? result = maybeOf(context);
    if (result == null) {
      throw StateError("No ArcaneEnvironment found in context");
    }
    return result;
  }

  @override
  bool updateShouldNotify(ArcaneEnvironment oldWidget) {
    return environment != oldWidget.environment;
  }

  void setEnvironment(Environment environment) =>
      _switchEnvironment(environment);

  void enableDebugMode() => _switchEnvironment(Environment.debug);
  void disableDebugMode() => _switchEnvironment(Environment.normal);
}

/// A `StatefulWidget` that manages and provides the `ArcaneEnvironment`.
///
/// This widget holds the internal state of the environment and rebuilds
/// its descendants when the environment changes.
class ArcaneEnvironmentProvider extends StatefulWidget {
  /// The child widget that will have access to the `ArcaneEnvironment`.
  final Widget child;

  /// The initial environment state. Defaults to `Environment.normal`.
  final Environment environment;

  /// Creates an `ArcaneEnvironmentProvider`.
  const ArcaneEnvironmentProvider({
    required this.child,
    Key? key,
    this.environment = Environment.normal,
  }) : super(key: key);

  @override
  State<ArcaneEnvironmentProvider> createState() =>
      _ArcaneEnvironmentProviderState();
}

class _ArcaneEnvironmentProviderState extends State<ArcaneEnvironmentProvider>
    implements ArcaneEnvironmentModeController {
  late Environment _environment;

  void _handleEnvironmentChange() {
    if (!mounted) return;

    final nextEnvironment = Arcane.environment.current;
    if (nextEnvironment == _environment) return;

    setState(() {
      _environment = nextEnvironment;
    });
  }

  @override
  void initState() {
    super.initState();
    _environment = Arcane.environment.current;

    if (_environment != widget.environment) {
      Arcane.environment.setEnvironment(widget.environment);
      _environment = Arcane.environment.current;
    }

    Arcane.environment.notifier.addListener(_handleEnvironmentChange);
  }

  @override
  void dispose() {
    Arcane.environment.notifier.removeListener(_handleEnvironmentChange);
    super.dispose();
  }

  /// Enables debug mode by setting the environment to `Environment.debug`.
  @override
  void enableDebugMode() {
    if (_environment == Environment.debug) return;
    setEnvironment(Environment.debug);
  }

  /// Disables debug mode by setting the environment to `Environment.normal`.
  @override
  void disableDebugMode() {
    if (_environment == Environment.normal) return;
    setEnvironment(Environment.normal);
  }

  @override
  void setEnvironment(Environment environment) {
    Arcane.environment.setEnvironment(environment);
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneEnvironment(
      environment: _environment,
      switchEnvironment: setEnvironment,
      child: widget.child,
    );
  }
}
