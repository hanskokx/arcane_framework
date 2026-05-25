import "package:flutter/material.dart";

enum Feature {
  logging(true),
  authentication(true),
  ;

  final bool enabledAtStartup;
  const Feature(this.enabledAtStartup);
}

// Some colors we'll use for our example
const List<MaterialColor> colors = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.deepPurple,
];
