import "package:arcane_service/arcane_service.dart";
import "package:flutter/foundation.dart";

/// Adapts a pure-Dart [ArcaneValueListenable] into Flutter's [ValueListenable].
///
/// The core Arcane packages are Flutter-free, so they expose reactive state as
/// [ArcaneValueListenable]. Widgets that expect a Flutter [ValueListenable]
/// (such as [ValueListenableBuilder] or [ValueListenable]) can consume those
/// values through this adapter.
///
/// Creating a new adapter per build leaks listeners; prefer the
/// `ArcaneValueListenableBuilder` widget, or cache a single adapter when the
/// source is stable.
class ArcaneValueListenableAdapter<T> extends ChangeNotifier
    implements ValueListenable<T> {
  /// Creates an adapter that mirrors [source].
  ArcaneValueListenableAdapter(this._source) {
    _source.addListener(notifyListeners);
  }

  final ArcaneValueListenable<T> _source;

  @override
  T get value => _source.value;

  @override
  void dispose() {
    _source.removeListener(notifyListeners);
    super.dispose();
  }
}
