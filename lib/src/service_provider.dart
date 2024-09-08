import "package:arcane_framework/arcane_framework.dart";
import "package:collection/collection.dart";
import "package:flutter/widgets.dart";

class ArcaneServiceProvider extends InheritedNotifier {
  final List<ArcaneService> serviceInstances;

  @override
  const ArcaneServiceProvider({
    required this.serviceInstances,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(ArcaneServiceProvider oldWidget) {
    return true;
  }

  static ArcaneServiceProvider of(BuildContext context) {
    final ArcaneServiceProvider? result =
        context.dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>();

    if (result == null) {
      throw Exception("ArcaneServiceProvider not found in context");
    }

    return result;
  }
}

extension ServiceProvider on BuildContext {
  /// Provides the `serviceOfType` extension on `BuildContext` to find a given
  /// `ArcaneService` instance that has been registered in the
  /// `ArcaneServiceProvider`.
  ///
  /// Returns either the requested `ArcaneService.I` or null if one cannot be
  /// found.
  ///
  /// Usage:
  ///
  /// ```
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

abstract class ArcaneService with ChangeNotifier {}
