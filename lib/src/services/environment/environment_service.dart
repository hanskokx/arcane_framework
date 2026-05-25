import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";

/// A singleton service that stores and broadcasts the current application
/// environment.
class ArcaneEnvironmentService extends ArcaneService {
  ArcaneEnvironmentService._internal();

  static final ArcaneEnvironmentService _instance =
      ArcaneEnvironmentService._internal();

  /// Provides access to the singleton instance.
  static ArcaneEnvironmentService get I => _instance;

  final ValueNotifier<Environment> _notifier =
      ValueNotifier<Environment>(Environment.normal);

  /// A notifier that emits updates when [current] changes.
  ValueNotifier<Environment> get notifier => _notifier;

  StreamController<Environment>? _environmentStreamController;

  StreamController<Environment> get _environmentController {
    _environmentStreamController ??= StreamController<Environment>.broadcast();
    return _environmentStreamController!;
  }

  /// Stream of environment updates.
  Stream<Environment> get environmentChanges => I._environmentController.stream;

  /// The current application environment as a snapshot value.
  ///
  /// Reading this getter does not subscribe to changes and does not trigger
  /// widget rebuilds. Use [notifier] (for `ValueListenableBuilder`) or
  /// [environmentChanges] (for streams) when you need reactive updates.
  Environment get current => _notifier.value;

  /// Sets the environment when the incoming value is different.
  void setEnvironment(Environment environment) {
    if (_notifier.value == environment) return;
    _notifier.value = environment;
    _environmentController.add(_notifier.value);
  }

  /// Switches the app to [Environment.debug].
  void enableDebugMode() => setEnvironment(Environment.debug);

  /// Switches the app to [Environment.normal].
  void disableDebugMode() => setEnvironment(Environment.normal);

  /// Restores defaults and emits the current state.
  void reset() {
    _notifier.value = Environment.normal;
    _environmentController.add(_notifier.value);
  }

  @override
  void dispose() {
    unawaited(_environmentStreamController?.close());
    _environmentStreamController = null;
    super.dispose();
  }
}
