import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneReactiveTheme", () {
    late ArcaneReactiveTheme theme;

    setUp(() {
      theme = ArcaneReactiveTheme.I;
      Arcane.theme.reset();
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

      testWidgets(
          "switchTheme toggles from effective system mode, not always to dark",
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.dark),
            child: ArcaneApp(
              child: SizedBox(),
            ),
          ),
        );

        final BuildContext darkContext = tester.element(find.byType(SizedBox));
        theme.switchTheme(themeMode: ThemeMode.system);
        theme.setInitialTheme(darkContext);
        theme.switchTheme();

        expect(theme.currentThemeMode, equals(ThemeMode.light));

        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.light),
            child: ArcaneApp(
              child: SizedBox(),
            ),
          ),
        );

        final BuildContext lightContext = tester.element(find.byType(SizedBox));
        theme.switchTheme(themeMode: ThemeMode.system);
        theme.setInitialTheme(lightContext);
        theme.switchTheme();

        expect(theme.currentThemeMode, equals(ThemeMode.dark));
      });

      test("switching theme notifies theme mode stream", () async {
        ThemeMode? emittedMode;
        final subscription = theme.themeModeChanges.listen((mode) {
          emittedMode = mode;
        });

        theme.switchTheme();
        await Future<void>.delayed(Duration.zero);

        expect(emittedMode, equals(theme.currentThemeMode));
        await subscription.cancel();
      });

      test("theme mode stream works after listener cancellation", () async {
        ThemeMode? firstEmission;
        final firstSubscription = theme.themeModeChanges.listen((mode) {
          firstEmission = mode;
        });

        theme.switchTheme();
        await Future<void>.delayed(Duration.zero);
        expect(firstEmission, ThemeMode.dark);

        await firstSubscription.cancel();

        ThemeMode? secondEmission;
        final secondSubscription = theme.themeModeChanges.listen((mode) {
          secondEmission = mode;
        });

        theme.switchTheme();
        await Future<void>.delayed(Duration.zero);
        expect(secondEmission, ThemeMode.light);

        await secondSubscription.cancel();
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

      test("theme updates notify notifier and streams", () async {
        bool darkNotified = false;
        bool lightNotified = false;
        ThemeMode? emittedMode;
        ThemeData? emittedThemeData;

        final modeSubscription = theme.themeModeChanges.listen((mode) {
          emittedMode = mode;
        });

        final dataSubscription = theme.themeDataChanges.listen((themeData) {
          emittedThemeData = themeData;
        });

        theme.darkTheme.addListener(() {
          darkNotified = true;
        });

        theme.lightTheme.addListener(() {
          lightNotified = true;
        });

        final darkTheme = ThemeData.dark().copyWith(
          primaryColor: Colors.teal,
        );
        final lightTheme = ThemeData.light().copyWith(
          primaryColor: Colors.amber,
        );

        theme.setDarkTheme(darkTheme);
        theme.setLightTheme(lightTheme);
        await Future<void>.delayed(Duration.zero);

        expect(darkNotified, true);
        expect(lightNotified, true);
        expect(emittedThemeData, isNotNull);

        theme.switchTheme();
        await Future<void>.delayed(Duration.zero);
        expect(theme.currentThemeMode, ThemeMode.dark);
        expect(emittedMode, ThemeMode.dark);

        theme.switchTheme();
        await Future<void>.delayed(Duration.zero);
        expect(theme.currentThemeMode, ThemeMode.light);
        expect(emittedMode, ThemeMode.light);

        await modeSubscription.cancel();
        await dataSubscription.cancel();
      });
    });

    group("system theme following", () {
      setUp(() {
        Arcane.theme.reset();
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
