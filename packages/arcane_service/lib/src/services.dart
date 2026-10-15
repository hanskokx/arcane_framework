import "package:collection/collection.dart";

import "notifier.dart";
import "service.dart";

/// The singleton locator and holder of every registered [ArcaneService].
///
/// `ArcaneServices` is the single source of truth for the services available in
/// an application. It owns the [registry] notifier that [ArcaneServiceProvider]
/// (in `arcane_framework`) mirrors into the widget tree, and it provides the
/// context-free lookup helpers [ofType] and [requiredOfType].
///
/// Because this class has no Flutter dependency, it can be used from pure-Dart
/// entrypoints as well as Flutter apps. Context-aware lookups that honor
/// widget-tree overrides are provided by `BuildContext.service` in
/// `arcane_framework`.
class ArcaneServices {
  ArcaneServices._internal();

  static final ArcaneServices _instance = ArcaneServices._internal();

  /// Provides access to the singleton instance.
  static ArcaneServices get I => _instance;

  /// The notifier holding every registered service.
  ///
  /// Listeners are notified whenever the registered service list changes.
  final ArcaneValueNotifier<List<ArcaneService>> registry =
      ArcaneValueNotifier<List<ArcaneService>>(const <ArcaneService>[]);

  /// A snapshot of every registered service.
  List<ArcaneService> get services =>
      List<ArcaneService>.unmodifiable(registry.value);

  /// Whether no services are currently registered.
  bool get isEmpty => registry.value.isEmpty;

  /// Whether at least one service is currently registered.
  bool get isNotEmpty => registry.value.isNotEmpty;

  /// Replaces the registry with [services].
  void register(List<ArcaneService> services) {
    registry.value = List<ArcaneService>.unmodifiable(services);
  }

  /// Adds [service], replacing any existing service of the same runtime type.
  void add(ArcaneService service) {
    final List<ArcaneService> next = List<ArcaneService>.from(registry.value);
    final int existingIndex = next.indexWhere(
      (ArcaneService current) => current.runtimeType == service.runtimeType,
    );

    if (existingIndex >= 0) {
      next[existingIndex] = service;
    } else {
      next.add(service);
    }

    registry.value = List<ArcaneService>.unmodifiable(next);
  }

  /// Removes every service of type [T].
  ///
  /// Returns `true` when at least one service was removed.
  bool remove<T extends ArcaneService>() {
    final List<ArcaneService> next = List<ArcaneService>.from(registry.value);
    final int originalLength = next.length;

    next.removeWhere((ArcaneService service) => service.runtimeType == T);

    if (next.length == originalLength) return false;

    registry.value = List<ArcaneService>.unmodifiable(next);
    return true;
  }

  /// Clears the registry.
  void clear() => registry.value = const <ArcaneService>[];

  /// Returns the first registered service of type [T], if any.
  T? ofType<T extends ArcaneService>() =>
      registry.value.whereType<T>().firstOrNull;

  /// Returns the first registered service of type [T].
  ///
  /// Throws an [AssertionError] when no matching service is registered.
  T requiredOfType<T extends ArcaneService>() {
    final T? service = ofType<T>();
    assert(service != null, "No service of type $T found");
    return service!;
  }
}
