import "package:meta/meta.dart";

/// A lightweight, pure-Dart implementation of the observer pattern.
///
/// This mirrors the ergonomics of Flutter's `ChangeNotifier` without pulling a
/// Flutter dependency into the core service packages. Services that need to
/// broadcast state changes mix this in and call [notifyListeners] whenever
/// their observable state changes.
mixin ArcaneChangeNotifier {
  final List<void Function()> _listeners = <void Function()>[];
  bool _disposed = false;

  /// Whether any listeners are currently registered.
  bool get hasListeners => _listeners.isNotEmpty;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Registers [listener] to be called when [notifyListeners] runs.
  void addListener(void Function() listener) {
    assert(!_disposed, "Cannot add a listener to a disposed notifier.");
    _listeners.add(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Invokes every registered listener.
  ///
  /// A snapshot of the listener list is iterated so listeners may safely
  /// add or remove listeners during notification.
  @protected
  void notifyListeners() {
    if (_disposed || _listeners.isEmpty) return;
    for (final void Function() listener in List<void Function()>.from(
      _listeners,
    )) {
      listener();
    }
  }

  /// Discards all listeners and marks this notifier as disposed.
  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}

/// A read-only view over a single value of type [T] that can be listened to.
abstract interface class ArcaneValueListenable<T> {
  /// The current value.
  T get value;

  /// Registers [listener] to be called when the value changes.
  void addListener(void Function() listener);

  /// Removes a previously registered [listener].
  void removeListener(void Function() listener);
}

/// A pure-Dart value holder that notifies listeners when [value] changes.
///
/// This is the decoupled counterpart to Flutter's `ValueNotifier`, allowing the
/// core service packages to expose reactive state without depending on Flutter.
class ArcaneValueNotifier<T>
    with ArcaneChangeNotifier
    implements ArcaneValueListenable<T> {
  /// Creates a notifier holding an initial [value].
  ArcaneValueNotifier(this._value);

  T _value;

  @override
  T get value => _value;

  /// Updates [value] and notifies listeners when it differs from the previous
  /// value.
  set value(T newValue) {
    if (newValue == _value) return;
    _value = newValue;
    notifyListeners();
  }
}
