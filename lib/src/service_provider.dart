import "package:arcane_service/arcane_service.dart";
import "package:flutter/widgets.dart";

/// Bridges the pure-Dart [ArcaneServices.registry] into Flutter's [Listenable].
///
/// [ArcaneServices] intentionally has no Flutter dependency, so its registry is
/// an [ArcaneValueNotifier]. This adapter re-broadcasts registry changes as a
/// Flutter [ChangeNotifier] so an [InheritedNotifier] can drive rebuilds.
class ArcaneServicesListenable extends ChangeNotifier {
  ArcaneServicesListenable._(this._registry) {
    _registry.addListener(_onRegistryChanged);
  }

  static final ArcaneServicesListenable _instance = ArcaneServicesListenable._(
    ArcaneServices.I.registry,
  );

  /// The shared adapter over the Arcane service registry.
  static ArcaneServicesListenable get I => _instance;

  final ArcaneValueNotifier<List<ArcaneService>> _registry;

  void _onRegistryChanged() => notifyListeners();
}

/// Exposes the Arcane service registry to the widget tree.
///
/// The registry itself lives in [ArcaneServices] (the single source of truth);
/// this widget only mirrors it into the tree so that widgets depending on it
/// rebuild when services are added, replaced, removed, or cleared.
class ArcaneServiceProvider
    extends InheritedNotifier<ArcaneServicesListenable> {
  /// Creates an `ArcaneServiceProvider` for [child].
  ArcaneServiceProvider({
    required super.child,
    super.key,
  }) : super(notifier: ArcaneServicesListenable.I);

  /// A snapshot of the currently registered services.
  List<ArcaneService> get registeredServices => ArcaneServices.I.services;

  /// Retrieves the nearest `ArcaneServiceProvider` in the widget tree.
  ///
  /// Returns null if no provider is found.
  static ArcaneServiceProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>();
  }

  /// Retrieves the nearest `ArcaneServiceProvider` in the widget tree.
  ///
  /// Throws an assertion error if no provider is found.
  static ArcaneServiceProvider of(BuildContext context) {
    final ArcaneServiceProvider? provider = maybeOf(context);
    assert(provider != null, "No ArcaneServiceProvider found in context");
    return provider!;
  }

  /// Returns the registered service of type [T], if any.
  ///
  /// Depending on this establishes a tree dependency so the calling widget
  /// rebuilds when the registry changes.
  static T? serviceOfType<T extends ArcaneService>(BuildContext context) {
    // Establish the inherited dependency for reactive rebuilds.
    maybeOf(context);
    return ArcaneServices.I.ofType<T>();
  }

  /// Returns the registered service of type [T].
  ///
  /// Throws an assertion error when no matching service is registered.
  static T requiredServiceOfType<T extends ArcaneService>(
    BuildContext context,
  ) {
    final T? service = serviceOfType<T>(context);
    assert(service != null, "No service of type $T found");
    return service!;
  }

  /// Replaces the registered services.
  void setServices(List<ArcaneService> newServices) =>
      ArcaneServices.I.register(newServices);

  /// Adds a service, replacing any existing service of the same runtime type.
  void addService(ArcaneService service) => ArcaneServices.I.add(service);

  /// Removes every service of type [T]; returns whether anything was removed.
  bool removeService<T extends ArcaneService>() => ArcaneServices.I.remove<T>();
}
