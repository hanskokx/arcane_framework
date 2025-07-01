import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneReactiveTheme", () {
    late ArcaneReactiveTheme theme;

    setUp(() {
      theme = ArcaneReactiveTheme.I;
      theme.reset();
    });

    tearDown(() {
      theme.reset();
    });

    test("singleton instance is consistent", () {
      expect(identical(ArcaneReactiveTheme.I, theme), true);
    });

    group("theme mode", () {
      test("initial mode is light", () {
        expect(theme.currentThemeMode, equals(ThemeMode.light));
      });

      test("switchTheme toggles between light and dark", () {
        expect(theme.currentThemeMode, equals(ThemeMode.light));
        theme.switchTheme();
        expect(theme.currentThemeMode, equals(ThemeMode.dark));
        theme.switchTheme();
        expect(theme.currentThemeMode, equals(ThemeMode.light));
      });

      test("switching theme notifies listeners", () {
        var notified = false;
        theme.themeModeChanges.addListener(() => notified = true);
        theme.switchTheme();
        expect(notified, true);
      });
    });

    group("theme customization", () {
      test("setDarkTheme updates dark theme", () {
        final customTheme = ThemeData.dark().copyWith(
          primaryColor: Colors.purple,
        );
        theme.setDarkTheme(customTheme);
        expect(theme.dark.primaryColor, equals(Colors.purple));
      });

      test("setLightTheme updates light theme", () {
        final customTheme = ThemeData.light().copyWith(
          primaryColor: Colors.orange,
        );
        theme.setLightTheme(customTheme);
        expect(theme.light.primaryColor, equals(Colors.orange));
      });

      test("theme updates notify listeners", () {
        bool darkNotified = false;
        bool lightNotified = false;
        ThemeMode currentTheme = theme.currentThemeMode;

        theme.darkTheme.addListener(() {
          darkNotified = true;
        });

        theme.lightTheme.addListener(() {
          lightNotified = true;
        });

        theme.themeModeChanges.addListener(() {
          currentTheme = theme.currentThemeMode;
        });

        expect(currentTheme, ThemeMode.light);

        // Use custom themes to ensure ValueNotifier detects changes
        final customDarkTheme = ThemeData.dark().copyWith(
          primaryColor: Colors.purple,
        );
        final customLightTheme = ThemeData.light().copyWith(
          primaryColor: Colors.orange,
        );

        theme.setDarkTheme(customDarkTheme);
        theme.setLightTheme(customLightTheme);

        expect(darkNotified, true);
        expect(lightNotified, true);

        theme.switchTheme();
        expect(currentTheme, ThemeMode.dark);

        theme.switchTheme();
        expect(currentTheme, ThemeMode.light);
      });
    });

    group("system theme following", () {
      setUp(() {
        theme.reset();
      });

      tearDown(() {
        theme.reset();
      });

      testWidgets("followSystemTheme updates theme based on context brightness",
          (WidgetTester tester) async {
        // Create widgets with different brightness contexts
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.light),
            child: ArcaneApp(
              child: SizedBox(),
            ),
          ),
        );

        final BuildContext lightContext = tester.element(find.byType(SizedBox));
        Arcane.theme.followSystemTheme(lightContext);
        await tester.pumpAndSettle();

        expect(theme.currentThemeMode, equals(ThemeMode.light));

        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.dark),
            child: ArcaneApp(
              child: SizedBox(),
            ),
          ),
        );

        final BuildContext darkContext = tester.element(find.byType(SizedBox));
        Arcane.theme.followSystemTheme(darkContext);
        await tester.pumpAndSettle();

        expect(theme.currentThemeMode, equals(ThemeMode.dark));
      });
    });
  });
}
