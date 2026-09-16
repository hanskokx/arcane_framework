part of "theme_service.dart";

/// Builds the theme state map for the DevTools `ext.arcane.devtools.invoke`
/// extension.
///
/// Internal to the framework; not part of the public API.
@internal
Map<String, Object?> arcaneThemeDevToolsState() {
  final ArcaneThemeService service = ArcaneThemeService.I;
  return <String, Object?>{
    "mode": service.currentThemeMode.name,
    "followingSystem": service.isFollowingSystemTheme,
    "customThemeRegistered": service._themeOverriddenByUser,
    "currentThemeMode": service.currentThemeMode.name,
    "followsSystemTheme": service.isFollowingSystemTheme,
    "systemThemeMode": service.systemThemeMode.name,
    "activeBrightness": service.currentTheme.brightness.name,
    "lightPrimaryColor": _colorHex(service.light.colorScheme.primary),
    "darkPrimaryColor": _colorHex(service.dark.colorScheme.primary),
  };
}

String _colorHex(Color color) =>
    "#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0").toUpperCase()}";

/// Applies a theme mode change for the DevTools
/// `ext.arcane.devtools.invoke` extension and returns the resulting theme
/// state.
///
/// Throws an [ArgumentError] when [params] lacks a valid `mode` (one of
/// "light", "dark", or "system"). Internal to the framework; not part of the
/// public API.
@internal
Map<String, Object?> arcaneThemeDevToolsSetMode(
  Map<String, Object?> params,
) {
  switch (params["mode"]) {
    case "light":
      ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.light);
    case "dark":
      ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.dark);
    case "system":
      ArcaneThemeService.I.switchTheme(themeMode: ThemeMode.system);
    default:
      throw ArgumentError.value(
        params["mode"],
        "mode",
        "Expected one of: light, dark, system.",
      );
  }
  return arcaneThemeDevToolsState();
}
