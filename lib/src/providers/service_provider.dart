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
/// final provider = ArcaneServiceProvider.of(context);
/// ```
class ArcaneServiceProvider extends InheritedNotifier {
  /// A list of `ArcaneService` instances available through the provider.
  final List<ArcaneService> serviceInstances;

  /// Creates an `ArcaneServiceProvider` that provides [serviceInstances] to the widget tree.
  ///
  /// The [child] widget will be the root of the widget subtree that has access to the services.
  @override
  const ArcaneServiceProvider({
    required this.serviceInstances,
    required super.child,
    super.key,
  });

  /// Determines whether the widget should notify its dependents.
  ///
  /// This always returns `true`, meaning dependents will always be notified
  /// when this widget is rebuilt.
  @override
  bool updateShouldNotify(_) => true;

  /// Retrieves the nearest `ArcaneServiceProvider` in the widget tree.
  ///
  /// This method is used to access the `ArcaneServiceProvider` and its provided services
  /// from any descendant widget. It throws an exception if no `ArcaneServiceProvider`
  /// is found in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final provider = ArcaneServiceProvider.of(context);
  /// ```
  static ArcaneServiceProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>();
  }
}

/// An extension on `BuildContext` to provide easy access to `ArcaneService` instances
/// that are registered in an `ArcaneServiceProvider`.
///
/// This extension provides a `serviceOfType` method, which searches for a specific
/// service of type `T` in the current `ArcaneServiceProvider` or in the list of built-in
/// services.
///
/// Example usage:
/// ```dart
/// final MyService? myService = context.serviceOfType<MyService>();
/// ```
extension ServiceProvider on BuildContext {
  /// Finds and returns the `ArcaneService` instance of type `T` that has been registered
  /// in the `ArcaneServiceProvider` or in the list of built-in services (`Arcane.services`).
  ///
  /// If no such service is found, it returns `null`.
  ///
  /// - `T`: The type of the service to be retrieved, which extends `ArcaneService`.
  ///
  /// Example:
  /// ```dart
  /// final MyService? myService = context.serviceOfType<MyService>();
  /// ```
  T? serviceOfType<T extends ArcaneService>() {
    final T? builtInService =
        Arcane.services.firstWhereOrNull((s) => s.runtimeType == T) as T?;

    if (builtInService != null) return builtInService;

    final T? foundService =
        dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>()
            ?.serviceInstances
            .firstWhereOrNull((s) => s.runtimeType == T) as T?;
    return foundService;
  }
}

/// An abstract class representing a service in the Arcane architecture.
///
/// Classes that extend `ArcaneService` can use `ChangeNotifier` functionality
/// to notify listeners of changes. Services are typically registered in
/// `ArcaneServiceProvider` and can be accessed using the `serviceOfType`
/// method on `BuildContext`.
abstract class ArcaneService<T> with ChangeNotifier {
  static T? of<T extends ArcaneService>(BuildContext context) =>
      context.serviceOfType();
}
