import "package:arcane_framework/arcane_framework.dart";
import "package:collection/collection.dart";
import "package:flutter/widgets.dart";

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
  List<ArcaneService> get serviceInstances => notifier!.value;

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

    return provider.serviceInstances.whereType<T>().firstOrNull;
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
    final int existingIndex = serviceInstances.indexWhere(
      (s) => s.runtimeType == service.runtimeType,
    );

    final List<ArcaneService> newList =
        List<ArcaneService>.from(serviceInstances);

    if (existingIndex >= 0) {
      newList[existingIndex] = service;
    } else {
      newList.add(service);
    }

    notifier?.value = newList;
  }
}

/// An extension on `BuildContext` to provide easy access to `ArcaneService` instances
/// that are registered in an `ArcaneServiceProvider`.
///
/// This extension provides methods for retrieving services in various ways.
///
/// Example usage:
/// ```dart
/// final myService = context.service<MyService>();
/// ```
extension ServiceProviderExtension on BuildContext {
  /// Finds and returns the `ArcaneService` instance of type `T` that has been registered
  /// in the `ArcaneServiceProvider` or in the list of built-in services (`Arcane.services`).
  ///
  /// If no such service is found, it returns `null`.
  ///
  /// Example:
  /// ```dart
  /// final myService = context.service<MyService>();
  /// ```
  T? service<T extends ArcaneService>() {
    // First check built-in services
    final builtInService = Arcane.services.whereType<T>().firstOrNull;
    if (builtInService != null) return builtInService;

    // Then check provider
    return ArcaneServiceProvider.serviceOfType<T>(this);
  }

  /// Finds and returns the `ArcaneService` instance of type `T` that has been registered
  /// in the `ArcaneServiceProvider` or in the list of built-in services (`Arcane.services`).
  ///
  /// Throws an assertion error if no service is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = context.requiredService<MyService>();
  /// ```
  T requiredService<T extends ArcaneService>() {
    final service = this.service<T>();
    assert(service != null, "No service of type $T found");
    return service!;
  }

  /// Legacy method to maintain backward compatibility.
  ///
  /// Prefer using `service<T>()` instead.
  @Deprecated("Use service<T>() instead")
  T? serviceOfType<T extends ArcaneService>() => service<T>();
}

/// An abstract class representing a service in the Arcane architecture.
///
/// Classes that extend `ArcaneService` can use `ChangeNotifier` functionality
/// to notify listeners of changes. Services are typically registered in
/// `ArcaneServiceProvider` and can be accessed using the `service`
/// method on `BuildContext`.
abstract class ArcaneService<T> with ChangeNotifier {}

extension ArcaneServiceLocators<T> on ArcaneService {
  /// Retrieves a service of the specified type from the context.
  ///
  /// Returns null if no service of type `T` is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = ArcaneService.of<MyService>(context);
  /// ```
  static T? of<T extends ArcaneService>(BuildContext context) =>
      context.service<T>();

  /// Retrieves a service of the specified type from the context.
  ///
  /// Throws an assertion error if no service of type `T` is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = ArcaneService.requiredOf<MyService>(context);
  /// ```
  static T requiredOf<T extends ArcaneService>(BuildContext context) =>
      context.requiredService<T>();
}
