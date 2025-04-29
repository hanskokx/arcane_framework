part of "arcane_service.dart";

/// A provider that makes a list of `ArcaneService` instances available to the widget tree.
///
/// This class extends `InheritedNotifier` and allows `ArcaneService` instances to be
/// accessed throughout the widget tree by descendant widgets. It should be used to
/// provide service instances that are shared across the application.
///
/// Example:
/// ```dart
/// ArcaneServiceProvider(
///   serviceInstances: [myService],
///   child: MyApp(),
/// );
/// ```
/// To access the provided services:
/// ```dart
/// final myService = ArcaneServiceProvider.of<MyService>(context);
/// ```
class ArcaneServiceProvider
    extends InheritedNotifier<ValueNotifier<List<ArcaneService>>> {
  /// A list of `ArcaneService` instances available through the provider.
  List<ArcaneService> get registeredServices =>
      List<ArcaneService>.from(notifier?.value ?? []);

  /// Creates an `ArcaneServiceProvider` that provides [serviceInstances] to the widget tree.
  ///
  /// The [child] widget will be the root of the widget subtree that has access to the services.
  ArcaneServiceProvider({
    required List<ArcaneService> serviceInstances,
    required super.child,
    super.key,
  }) : super(
          notifier: ValueNotifier<List<ArcaneService>>(serviceInstances),
        );

  /// Retrieves the nearest `ArcaneServiceProvider` in the widget tree.
  ///
  /// Returns null if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final provider = ArcaneServiceProvider.maybeOf(context);
  /// ```
  static ArcaneServiceProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>();
  }

  /// Retrieves the nearest `ArcaneServiceProvider` in the widget tree.
  ///
  /// Throws an assertion error if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final provider = ArcaneServiceProvider.of(context);
  /// ```
  static ArcaneServiceProvider of<T extends ArcaneService>(
    BuildContext context,
  ) {
    final provider = maybeOf(context);
    assert(provider != null, "No ArcaneServiceProvider found in context");
    return provider!;
  }

  /// Retrieves a service of type `T` from the nearest provider.
  ///
  /// Returns null if no service of type `T` is found or if no provider exists.
  ///
  /// Example:
  /// ```dart
  /// final myService = ArcaneServiceProvider.of<MyService>(context);
  /// ```
  static T? serviceOfType<T extends ArcaneService>(BuildContext context) {
    final provider = maybeOf(context);
    if (provider == null) return null;

    return provider.registeredServices.whereType<T>().firstOrNull;
  }

  /// Updates the service instances in this provider.
  ///
  /// This will trigger a rebuild of all widgets that depend on this provider.
  void setServices(List<ArcaneService> newServices) {
    notifier?.value = newServices;
  }

  /// Adds a new service to this provider.
  ///
  /// If a service of the same type already exists, it will be replaced.
  void addService(ArcaneService service) {
    final int existingIndex = registeredServices.indexWhere(
      (s) => s.runtimeType == service.runtimeType,
    );

    final List<ArcaneService> newList =
        List<ArcaneService>.from(registeredServices);

    if (existingIndex >= 0) {
      newList[existingIndex] = service;
    } else {
      newList.add(service);
    }

    notifier?.value = newList;
  }

  /// Removes all services of the specified type from the registry.
  /// Returns true if any services were removed, false otherwise.
  void removeService<T extends ArcaneService>() {
    final int existingIndex = registeredServices.indexWhere(
      (s) => s.runtimeType == T,
    );

    if (existingIndex >= 0) {
      final List<ArcaneService> newList =
          List<ArcaneService>.from(registeredServices);

      newList.removeAt(existingIndex);
      notifier?.value = newList;
    }
  }
}
