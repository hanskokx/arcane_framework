import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("isDarkMode returns true for dark theme", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            expect(context.isDarkMode, isTrue);
            return Container();
          },
        ),
      ),
    );
  });

  testWidgets("isDarkMode returns false for light theme", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            expect(context.isDarkMode, isFalse);
            return Container();
          },
        ),
      ),
    );
  });

  testWidgets("themeMode reads value from nearest ArcaneTheme", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArcaneTheme(
          themeMode: ThemeMode.dark,
          child: Builder(
            builder: (context) {
              expect(context.themeMode, ThemeMode.dark);
              return Container();
            },
          ),
        ),
      ),
    );
  });

  testWidgets("themeMode falls back to Arcane theme service without provider",
      (tester) async {
    Arcane.theme.reset();
    Arcane.theme.switchTheme(themeMode: ThemeMode.dark);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            expect(context.themeMode, ArcaneReactiveTheme.I.currentThemeMode);
            return Container();
          },
        ),
      ),
    );
  });
}
