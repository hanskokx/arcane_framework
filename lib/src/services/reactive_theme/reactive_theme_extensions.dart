part of "reactive_theme_service.dart";

/// An extension on `BuildContext` to check the current system dark mode setting.
///
/// This extension provides a convenient way to check whether the device is in dark mode.
extension DarkMode on BuildContext {
  /// Returns `true` if the system is currently set to dark mode.
  ///
  /// This uses `MediaQuery.of(this).platformBrightness` to check the system's brightness setting.
  ///
  /// Example:
  /// ```dart
  /// if (context.isDarkMode) {
  ///   // The system is in dark mode.
  /// }
  /// ```
  bool get isDarkMode {
    final brightness = MediaQuery.platformBrightnessOf(this);
    return brightness == Brightness.dark;
  }
}
