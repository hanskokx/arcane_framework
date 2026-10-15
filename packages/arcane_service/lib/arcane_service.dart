/// The core, Flutter-free service model for the Arcane framework.
///
/// This library defines [ArcaneService] (what a service *is*), [ArcaneServices]
/// (the singleton that holds and locates registered services), and the pure-Dart
/// notifier primitives ([ArcaneChangeNotifier], [ArcaneValueNotifier]) used to
/// expose reactive state without depending on Flutter.
///
/// Widget-tree integration and `BuildContext` lookups live in
/// `arcane_framework`.
library;

export "src/notifier.dart";
export "src/service.dart";
export "src/services.dart";
