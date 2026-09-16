import "dart:convert";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework/src/extension/arcane_service_extensions.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

/// A small feature set used by the extension tests.
enum _TestFeature {
  featureAlpha,
  featureBeta,
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Arcane.logger.reset();
    ArcaneFeatureFlagService.I.reset();
    Arcane.theme.switchTheme(themeMode: ThemeMode.system);
    Arcane.environment.setEnvironment(Environment.normal);

    ArcaneServiceExtensions.logBuffer.clear();
    // Make both features known (but not enabled) so the extension can toggle
    // them by name.
    Arcane.features
      ..enableFeature(_TestFeature.featureAlpha)
      ..disableFeature(_TestFeature.featureAlpha)
      ..enableFeature(_TestFeature.featureBeta)
      ..disableFeature(_TestFeature.featureBeta);
    ArcaneServiceExtensions.register();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    ArcaneFeatureFlagService.I.reset();
    Arcane.theme.switchTheme(themeMode: ThemeMode.system);
    Arcane.environment.setEnvironment(Environment.normal);
    ArcaneServiceExtensions.logBuffer.clear();
  });

  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?>? params,
  ]) async {
    return ArcaneServiceExtensions.handle(<String, String>{
      "method": method,
      if (params != null) "params": jsonEncode(params),
    });
  }

  group("ping", () {
    test("responds with an ok status", () async {
      final Map<String, Object?> response = await invoke("ping");
      expect(response["type"], "result");
      expect(
        (response["result"]! as Map<String, Object?>)["status"],
        "ok",
      );
    });
  });

  group("services & overview", () {
    test("services lists every built-in service with a summary", () async {
      final Map<String, Object?> response = await invoke("services");
      final List<Object?> services =
          (response["result"]! as Map<String, Object?>)["services"]!
              as List<Object?>;

      final List<String> types = <String>[
        for (final Object? service in services)
          (service! as Map<String, Object?>)["type"]! as String,
      ];
      expect(types, contains("ArcaneFeatureFlagService"));
      expect(types, contains("ArcaneAuthenticationService"));
      expect(types, contains("ArcaneThemeService"));
      expect(types, contains("ArcaneEnvironmentService"));
    });

    test("overview includes services and logger state", () async {
      final Map<String, Object?> response = await invoke("overview");
      final Map<String, Object?> result =
          response["result"]! as Map<String, Object?>;
      expect(result["app"], "arcane_framework");
      expect(
        (result["logging"] as Map<String, Object?>)["initialized"],
        isTrue,
      );
      expect(
        (result["featureFlags"] as Map<String, Object?>)["catalog"],
        isA<List<Object?>>(),
      );
    });
  });

  group("logs", () {
    test("surfaces events logged through Arcane.log", () async {
      Arcane.log(
        "bridge captures this",
        level: Level.info,
        metadata: const <String, Object?>{"module": "test"},
      );

      final Map<String, Object?> response = await invoke("logs");
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      final List<Object?> logs = data["logs"]! as List<Object?>;

      expect(logs, isNotEmpty);
      final Map<String, Object?> last = logs.last as Map<String, Object?>;
      expect(last["message"], "bridge captures this");
      expect(last["level"], "info");
      expect(last["module"], "test");
    });

    test("logs filters by level and search", () async {
      Arcane.log("deep trace", level: Level.trace);
      Arcane.log(
        "auth warning",
        level: Level.warning,
        metadata: const <String, Object?>{"module": "auth"},
      );

      final Map<String, Object?> response = await invoke(
        "logs",
        <String, Object?>{
          "level": "info",
          "search": "warning",
          "limit": 10,
        },
      );
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      final List<Object?> logs = data["logs"]! as List<Object?>;
      expect(logs, hasLength(1));
      expect((logs.single as Map<String, Object?>)["message"], "auth warning");
    });
  });

  group("feature flags", () {
    test("catalog reports the flags the app has toggled", () async {
      final Map<String, Object?> response = await invoke("feature_flags");
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      final List<Object?> catalog = data["catalog"]! as List<Object?>;
      expect(catalog, hasLength(_TestFeature.values.length));
      expect(
        (catalog.first as Map<String, Object?>)["name"],
        "featureAlpha",
      );
    });

    test("set_feature_flag toggles a known feature", () async {
      await invoke("set_feature_flag", <String, Object?>{
        "name": "featureAlpha",
        "enabled": true,
      });
      expect(Arcane.features.isEnabled(_TestFeature.featureAlpha), isTrue);

      final Map<String, Object?> response = await invoke(
        "set_feature_flag",
        <String, Object?>{"name": "featureAlpha", "enabled": false},
      );
      expect(Arcane.features.isEnabled(_TestFeature.featureAlpha), isFalse);
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["enabled"], isFalse);
    });

    test("set_feature_flag rejects names outside the known set", () async {
      final Map<String, Object?> response = await invoke(
        "set_feature_flag",
        <String, Object?>{"name": "unknownFlag", "enabled": true},
      );
      expect(response["type"], "error");
      expect(response["error"], contains("known"));
    });

    test("a previously disabled flag can be re-enabled by name", () async {
      Arcane.features.disableFeature(_TestFeature.featureBeta);
      final Map<String, Object?> response = await invoke(
        "set_feature_flag",
        <String, Object?>{"name": "featureBeta", "enabled": true},
      );
      expect(response["type"], "result");
      expect(Arcane.features.isEnabled(_TestFeature.featureBeta), isTrue);
    });
  });

  group("authentication", () {
    test("reports the current authentication state", () async {
      final Map<String, Object?> response = await invoke("authentication");
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["status"], "unknown");
      expect(data["authenticated"], isFalse);
      expect(data["signedIn"], isFalse);
    });

    test("includes tokens only when requested", () async {
      final Map<String, Object?> response = await invoke(
        "authentication",
        <String, Object?>{"includeTokens": true},
      );
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data.containsKey("accessToken"), isTrue);
    });
  });

  group("theme", () {
    test("reports the current theme mode", () async {
      final Map<String, Object?> response = await invoke("theme");
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["currentThemeMode"], "system");
      expect(data["activeBrightness"], anyOf("light", "dark"));
    });

    test("set_theme_mode switches the active theme", () async {
      final Map<String, Object?> response = await invoke(
        "set_theme_mode",
        <String, Object?>{"mode": "dark"},
      );
      expect(Arcane.theme.currentThemeMode, ThemeMode.dark);
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["currentThemeMode"], "dark");
    });

    test("set_theme_mode rejects unknown modes", () async {
      final Map<String, Object?> response = await invoke(
        "set_theme_mode",
        <String, Object?>{"mode": "sepia"},
      );
      expect(response["type"], "error");
      expect(response["error"], contains("light, dark, system"));
    });
  });

  group("environment", () {
    test("reports the current environment", () async {
      Arcane.environment.setEnvironment(Environment.debug);
      final Map<String, Object?> response = await invoke("environment");
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["name"], "debug");
      expect(data["debug"], isTrue);
    });

    test("set_environment supports built-ins and custom names", () async {
      final Map<String, Object?> response = await invoke(
        "set_environment",
        <String, Object?>{"name": "staging"},
      );
      final Map<String, Object?> data =
          response["result"]! as Map<String, Object?>;
      expect(data["name"], "staging");
      expect(data["debug"], isFalse);
      expect(Arcane.environment.current.name, "staging");
    });
  });

  group("error handling", () {
    test("unknown methods return an error", () async {
      final Map<String, Object?> response = await invoke("no_such_method");
      expect(response["type"], "error");
      expect(response["error"], contains("no_such_method"));
    });

    test("invalid params JSON returns an error", () async {
      final Map<String, Object?> response =
          await ArcaneServiceExtensions.handle(
            <String, String>{
              "method": "overview",
              "params": "not json",
            },
          );
      expect(response["type"], "error");
      expect(response["error"], contains("valid JSON"));
    });
  });
}
