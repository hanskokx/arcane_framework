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
      throw Exception("AppServiceProvider not found in context");
    }

    return result;
  }
}

extension ServiceProvider on BuildContext {
  /// Provides the `serviceOfType` extension on `BuildContext` to find a given
  /// `AppService` instance that has been registered in the
  /// `AppServiceProvider`.
  ///
  /// Returns either the requested `AppService.I` or null if one cannot be
  /// found.
  ///
  /// Usage:
  ///
  /// ```
  /// final MyService? myService = context.serviceOfType<MyService>();
  /// ```
  T? serviceOfType<T extends ArcaneService>() =>
      dependOnInheritedWidgetOfExactType<ArcaneServiceProvider>()
          ?.serviceInstances
          .firstWhereOrNull((s) => s.runtimeType == T) as T?;
}

abstract class ArcaneService with ChangeNotifier {}
