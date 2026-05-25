import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

class FavoriteColorService extends ArcaneService {
  FavoriteColorService();

  MaterialColor? get myFavoriteColor => _notifier.value;

  final ValueNotifier<MaterialColor?> _notifier =
      ValueNotifier<MaterialColor?>(null);

  ValueNotifier<MaterialColor?> get notifier => _notifier;

  void setMyFavoriteColor(MaterialColor? newValue) {
    if (_notifier.value == newValue) return;

    _notifier.value = newValue;

    if (newValue == null) return;

    // Apply the seed to whichever theme is currently being rendered.
    final bool isUsingDarkTheme =
        Arcane.theme.currentTheme.brightness == Brightness.dark;
    if (isUsingDarkTheme) {
      Arcane.theme.setDarkTheme(
        ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: newValue,
        ),
      );
    } else {
      Arcane.theme.setLightTheme(
        ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: newValue,
        ),
      );
    }
  }

  void syncFromCurrentTheme(Iterable<MaterialColor> palette) {
    final Iterator<MaterialColor> iterator = palette.iterator;
    if (!iterator.moveNext()) {
      _notifier.value = null;
      return;
    }

    final Color target = Arcane.theme.currentTheme.colorScheme.primary;
    MaterialColor closest = iterator.current;
    double closestDistance = _colorDistanceSquared(closest, target);

    while (iterator.moveNext()) {
      final MaterialColor candidate = iterator.current;
      final double distance = _colorDistanceSquared(candidate, target);
      if (distance < closestDistance) {
        closest = candidate;
        closestDistance = distance;
      }
    }

    if (_notifier.value != closest) {
      _notifier.value = closest;
    }
  }

  double _colorDistanceSquared(Color a, Color b) {
    final double dr = a.r - b.r;
    final double dg = a.g - b.g;
    final double db = a.b - b.b;
    return (dr * dr) + (dg * dg) + (db * db);
  }
}

extension MaterialColorName on MaterialColor {
  String? get name {
    final double red = double.parse(r.toStringAsFixed(4));
    final double green = double.parse(g.toStringAsFixed(4));
    final double blue = double.parse(b.toStringAsFixed(4));
    if (red == 0.9569 && green == 0.2627 && blue == 0.2118) return "red";
    if (red == 1 && green == 0.5961 && blue == 0) return "orange";
    if (red == 1 && green == 0.9216 && blue == 0.2314) return "yellow";
    if (red == 0.2980 && green == 0.6863 && blue == 0.3137) return "green";
    if (red == 0.1294 && green == 0.5882 && blue == 0.9529) return "blue";
    if (red == 0.6118 && green == 0.1529 && blue == 0.6902) return "indigo";
    if (red == 0.4039 && green == 0.2275 && blue == 0.7176) return "violet";

    return null;
  }
}

extension ColorName on Color {
  String? get name {
    final double red = double.parse(r.toStringAsFixed(4));
    final double green = double.parse(g.toStringAsFixed(4));
    final double blue = double.parse(b.toStringAsFixed(4));

    if (red == 0.5647 && green == 0.2902 && blue == 0.2588) return "red";
    if (red == 0.5216 && green == 0.3255 && blue == 0.0941) return "orange";
    if (red == 0.4078 && green == 0.3725 && blue == 0.0706) return "yellow";
    if (red == 0.2314 && green == 0.4118 && blue == 0.2235) return "green";
    if (red == 0.2118 && green == 0.3804 && blue == 0.5569) return "blue";
    if (red == 0.4824 && green == 0.3059 && blue == 0.498) return "indigo";
    if (red == 0.4078 && green == 0.3294 && blue == 0.5569) return "violet";

    return null;
  }
}
