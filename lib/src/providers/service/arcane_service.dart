import "package:arcane_framework/arcane_framework.dart";
import "package:collection/collection.dart";
import "package:flutter/widgets.dart";

part "service_provider.dart";
part "service_provider_extensions.dart";

/// An abstract class representing a service in the Arcane architecture.
///
/// Classes that extend `ArcaneService` can use `ChangeNotifier` functionality
/// to notify listeners of changes. Services are typically registered in
/// `ArcaneServiceProvider` and can be accessed using the `service`
/// method on `BuildContext`.
abstract class ArcaneService with ChangeNotifier {
  /// Retrieves a service of the specified type from the context.
  ///
  /// Returns null if no service of type `T` is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = ArcaneService.ofType<MyService>(context);
  /// ```
  static T? ofType<T extends ArcaneService>(BuildContext context) =>
      context.service<T>();

  /// Retrieves a service of the specified type from the context.
  ///
  /// Throws an assertion error if no service of type `T` is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = ArcaneService.requiredOfType<MyService>(context);
  /// ```
  static T requiredOfType<T extends ArcaneService>(BuildContext context) =>
      context.requiredService<T>();
}
