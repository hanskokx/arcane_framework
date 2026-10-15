import "package:arcane_service/arcane_service.dart";
import "package:flutter/widgets.dart";

/// A Flutter builder that rebuilds when an [ArcaneValueListenable] changes.
///
/// This is the Flutter-facing counterpart to `ValueListenableBuilder` for the
/// Flutter-free reactive values exposed by the core Arcane packages.
///
/// Example:
/// ```dart
/// ArcaneValueListenableBuilder<List<Enum>>(
///   valueListenable: Arcane.features.notifier,
///   builder: (context, features, _) => Text('$features'),
/// )
/// ```
class ArcaneValueListenableBuilder<T> extends StatefulWidget {
  /// Creates a builder driven by [valueListenable].
  const ArcaneValueListenableBuilder({
    required this.valueListenable,
    required this.builder,
    this.child,
    super.key,
  });

  /// The value being listened to.
  final ArcaneValueListenable<T> valueListenable;

  /// Called to build the widget whenever [valueListenable] changes.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// An optional child passed to [builder]; it is not rebuilt.
  final Widget? child;

  @override
  State<ArcaneValueListenableBuilder<T>> createState() =>
      _ArcaneValueListenableBuilderState<T>();
}

class _ArcaneValueListenableBuilderState<T>
    extends State<ArcaneValueListenableBuilder<T>> {
  void _handleChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.valueListenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant ArcaneValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_handleChange);
      widget.valueListenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.valueListenable.value, widget.child);
}
