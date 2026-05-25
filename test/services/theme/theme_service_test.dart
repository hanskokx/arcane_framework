import "package:arcane_framework/src/services/theme/theme_service.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneThemeService", () {
    setUp(() {
      ArcaneThemeService.I.reset();
    });

    test("default state is light theme, not following system", () {
      expect(ArcaneThemeService.I.isFollowingSystemTheme, isFalse);
      expect(ArcaneThemeService.I.currentThemeMode, ThemeMode.light);
      expect(ArcaneThemeService.I.currentTheme, isA<ThemeData>());
    });

    test("switchTheme toggles between light and dark", () {
      ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.light);
      expect(ArcaneThemeService.I.currentThemeMode, ThemeMode.light);
      ArcaneThemeService.I.switchTheme();
      expect(ArcaneThemeService.I.currentThemeMode, ThemeMode.dark);
      ArcaneThemeService.I.switchTheme();
      expect(ArcaneThemeService.I.currentThemeMode, ThemeMode.light);
    });

    test("setDarkTheme and setLightTheme update themes", () {
      final customDark =
          ThemeData(primaryColor: Colors.red, brightness: Brightness.dark);
      final customLight =
          ThemeData(primaryColor: Colors.blue, brightness: Brightness.light);
      ArcaneThemeService.I.setDarkTheme(customDark);
      expect(ArcaneThemeService.I.dark, customDark);
      ArcaneThemeService.I.setLightTheme(customLight);
      expect(ArcaneThemeService.I.light, customLight);
    });

    test("reset restores defaults", () {
      ArcaneThemeService.I.setDarkTheme(
          ThemeData(primaryColor: Colors.red, brightness: Brightness.dark),);
      ArcaneThemeService.I.setLightTheme(
          ThemeData(primaryColor: Colors.blue, brightness: Brightness.light),);
      ArcaneThemeService.I.reset();
      expect(ArcaneThemeService.I.dark, ThemeData.dark());
      expect(ArcaneThemeService.I.light, ThemeData.light());
      expect(ArcaneThemeService.I.isFollowingSystemTheme, isFalse);
    });

    test("dispose does not throw", () {
      ArcaneThemeService.I.dispose();
    });
  });
}
