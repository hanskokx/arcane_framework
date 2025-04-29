part of "arcane_service.dart";

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
