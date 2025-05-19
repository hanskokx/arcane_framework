import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";

/// An `InheritedWidget` that provides access to the application environment.
///
/// The `ArcaneEnvironment` widget holds the current environment (`debug` or `normal`)
/// and allows descendant widgets to access it.
class ArcaneEnvironment extends InheritedWidget {
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

class _ArcaneEnvironmentProviderState extends State<ArcaneEnvironmentProvider> {
  late Environment _environment;

  @override
  void initState() {
    super.initState();
    _environment = widget.environment;
  }

  /// Enables debug mode by setting the environment to `Environment.debug`.
  void enableDebugMode() {
    if (_environment == Environment.debug) return;
    setState(() {
      _environment = Environment.debug;
    });
  }

  /// Disables debug mode by setting the environment to `Environment.normal`.
  void disableDebugMode() {
    if (_environment == Environment.normal) return;
    setState(() {
      _environment = Environment.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ArcaneEnvironment(
      environment: _environment,
      switchEnvironment: (Environment environment) {
        setState(() {
          _environment = environment;
        });
      },
      child: widget.child,
    );
  }
}
