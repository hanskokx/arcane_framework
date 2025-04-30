import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

class FavoriteColorService extends ArcaneService {
  static final FavoriteColorService _instance =
      FavoriteColorService._internal();

  static FavoriteColorService get I => _instance;

  FavoriteColorService._internal();

  MaterialColor? get myFavoriteColor => _notifier.value;

  final ValueNotifier<MaterialColor?> _notifier =
      ValueNotifier<MaterialColor?>(null);

  ValueNotifier<MaterialColor?> get notifier => _notifier;

  void setMyFavoriteColor(MaterialColor? newValue) {
    if (_notifier.value != newValue) {
      _notifier.value = newValue;
    }

    notifyListeners();
  }
}

extension ColorName on MaterialColor {
  String get name {
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

    return "";
  }
}
