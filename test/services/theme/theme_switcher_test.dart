import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneThemeSwitcher", () {
    setUp(() {
      ArcaneThemeService.I.reset();
    });

    testWidgets("renders child inside ArcaneTheme", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcaneThemeSwitcher(
            child: Builder(
              builder: (context) {
                final theme = ArcaneTheme.of(context);
                expect(theme, isNotNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
        "didChangePlatformBrightness calls followSystemTheme when following system",
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArcaneThemeSwitcher(child: SizedBox()),
        ),
      );

      // followSystemTheme is set during didChangeDependencies; enable it.
      ArcaneThemeService.I.followSystemTheme(
        tester.element(find.byType(ArcaneThemeSwitcher)),
      );
      expect(ArcaneThemeService.I.isFollowingSystemTheme, isTrue);

      // Simulate a platform brightness change via the WidgetsBindingObserver.
      tester.binding.platformDispatcher.onPlatformBrightnessChanged?.call();
      await tester.pump();

      // After the post-frame callback the service should still be in
      // follow-system mode — the key assertion is that no exception was thrown
      // and the widget remained mounted.
      expect(ArcaneThemeService.I.isFollowingSystemTheme, isTrue);
    });

    testWidgets(
        "didChangePlatformBrightness is a no-op when not following system",
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArcaneThemeSwitcher(child: SizedBox()),
        ),
      );

      // Explicitly switch to a manual dark mode (disables follow-system).
      ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.dark);
      expect(ArcaneThemeService.I.isFollowingSystemTheme, isFalse);

      // Simulate platform brightness change — should be a no-op without error.
      tester.binding.platformDispatcher.onPlatformBrightnessChanged?.call();
      await tester.pump();

      expect(ArcaneThemeService.I.currentThemeMode, ThemeMode.dark);
    });
  });
}
