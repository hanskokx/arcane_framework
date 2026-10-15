import "notifier.dart";

/// The base class for every service in the Arcane architecture.
///
/// `ArcaneService` defines *what a service is*: a long-lived, disposable object
/// that can broadcast change notifications through [ArcaneChangeNotifier]. It
/// deliberately has no dependency on Flutter so the same service model can be
/// reused by CLI tools, servers, and tests.
///
/// Concrete services are typically written as singletons (for example
/// `ArcaneEnvironmentService.I`) and registered with [ArcaneServices].
abstract class ArcaneService with ArcaneChangeNotifier {}
