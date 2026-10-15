import "package:arcane_framework/src/arcane.dart";
import "package:arcane_framework/src/service_provider.dart";
import "package:flutter/widgets.dart";

/// Convenience accessors for `ArcaneService` instances from `BuildContext`.
///
/// Lookups first consult the nearest [ArcaneServiceProvider] (so widget-tree
/// state wins) and then fall back to Arcane's registered services.
///
/// Example:
/// ```dart
/// final myService = context.service<MyService>();
/// ```
extension ServiceProviderExtension on BuildContext {
  /// Returns the service of type [T], or `null` when none is available.
  ///
  /// Depending on this establishes a tree dependency so the calling widget
  /// rebuilds when the registered services change.
  T? service<T extends ArcaneService>() {
    // Consult the provider first so widget-tree state wins.
    final T? providerService = ArcaneServiceProvider.serviceOfType<T>(this);
    if (providerService != null) return providerService;

    // Fall back to Arcane's registered (or built-in) services.
    return Arcane.services.whereType<T>().firstOrNull;
  }

  /// Returns the service of type [T].
  ///
  /// Throws an assertion error when no matching service is available.
  T requiredService<T extends ArcaneService>() {
    final T? service = this.service<T>();
    assert(service != null, "No service of type $T found");
    return service!;
  }

  /// Legacy alias for [service].
  @Deprecated("Deprecated in 2.0.0. Use service<T>() instead.")
  T? serviceOfType<T extends ArcaneService>() => service<T>();
}
