import "package:arcane_framework/src/services/theme/theme_extensions.dart";
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
}
