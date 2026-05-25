import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneThemeService regression", () {
    setUp(() {
      Arcane.theme.reset();
    });

    test("setDarkTheme does not update rendered theme if not in dark mode", () {
      // Start in light mode
      expect(Arcane.theme.currentThemeMode, ThemeMode.light);
      final originalTheme = Arcane.theme.currentTheme;
      final darkTheme = ThemeData.dark().copyWith(primaryColor: Colors.purple);
      Arcane.theme.setDarkTheme(darkTheme);
      // Should not update rendered theme
      expect(Arcane.theme.currentTheme, originalTheme);
      expect(Arcane.theme.dark.primaryColor, Colors.purple);
    });

    test("setLightTheme does not update rendered theme if not in light mode",
        () {
      Arcane.theme.switchTheme(themeMode: ThemeMode.dark);
      expect(Arcane.theme.currentThemeMode, ThemeMode.dark);
      final originalTheme = Arcane.theme.currentTheme;
      final lightTheme =
          ThemeData.light().copyWith(primaryColor: Colors.orange);
      Arcane.theme.setLightTheme(lightTheme);
      // Should not update rendered theme
      expect(Arcane.theme.currentTheme, originalTheme);
      expect(Arcane.theme.light.primaryColor, Colors.orange);
    });

    test("setDarkTheme updates rendered theme if in dark mode", () {
      Arcane.theme.switchTheme(themeMode: ThemeMode.dark);
      expect(Arcane.theme.currentThemeMode, ThemeMode.dark);
      final darkTheme = ThemeData.dark().copyWith(primaryColor: Colors.green);
      Arcane.theme.setDarkTheme(darkTheme);
      expect(Arcane.theme.currentTheme, darkTheme);
    });

    test("setLightTheme updates rendered theme if in light mode", () {
      expect(Arcane.theme.currentThemeMode, ThemeMode.light);
      final lightTheme = ThemeData.light().copyWith(primaryColor: Colors.blue);
      Arcane.theme.setLightTheme(lightTheme);
      expect(Arcane.theme.currentTheme, lightTheme);
    });
  });
}
