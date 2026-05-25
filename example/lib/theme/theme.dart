import "package:flutter/material.dart";

const MaterialColor defaultSeedColor = Colors.blue;

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: defaultSeedColor,
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorSchemeSeed: defaultSeedColor,
);
