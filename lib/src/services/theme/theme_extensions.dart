import "package:flutter/material.dart";

import "arcane_theme.dart";
import "theme_service.dart";

/// An extension on `BuildContext` to check the current effective dark mode.
///
/// This extension provides a convenient way to check whether the active
/// `ThemeData` is dark in the current context.
extension DarkMode on BuildContext {
  /// Returns `true` if the current effective theme is dark.
  ///
  /// This uses `Theme.of(this).brightness`, so it reflects the app's active
  /// rendered theme rather than raw platform brightness.
  ///
  /// Example:
  /// ```dart
  /// if (context.isDarkMode) {
  ///   // The active app theme is dark.
  /// }
  /// ```
  bool get isDarkMode {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark;
  }
}

extension ArcaneThemeContext on BuildContext {
  /// Get the current theme mode from the nearest ArcaneThemeInherited widget
  ThemeMode get themeMode {
    return ArcaneTheme.of(this)?.themeMode ??
        ArcaneReactiveTheme.I.currentThemeMode;
  }
}
