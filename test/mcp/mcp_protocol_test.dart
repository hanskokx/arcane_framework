import "package:arcane_framework/src/mcp/protocol.dart";
import "package:test/test.dart";

void main() {
  group("constants", () {
    test("service extension is ext.arcane.devtools.invoke", () {
      expect(arcaneMcpServiceExtension, "ext.arcane.devtools.invoke");
    });

    test("methods include the full read/mutate set", () {
      expect(ArcaneMcpMethods.ping, "ping");
      expect(ArcaneMcpMethods.overview, "overview");
      expect(ArcaneMcpMethods.services, "services");
      expect(ArcaneMcpMethods.logs, "logs");
      expect(ArcaneMcpMethods.featureFlags, "feature_flags");
      expect(ArcaneMcpMethods.setFeatureFlag, "set_feature_flag");
      expect(ArcaneMcpMethods.authentication, "authentication");
      expect(ArcaneMcpMethods.theme, "theme");
      expect(ArcaneMcpMethods.setThemeMode, "set_theme_mode");
      expect(ArcaneMcpMethods.environment, "environment");
      expect(ArcaneMcpMethods.setEnvironment, "set_environment");
      expect(ArcaneMcpMethods.setAuthStatus, "set_auth_status");
    });

    test("method and parameter keys are distinct namespaces", () {
      expect(ArcaneMcpMethods.services, isNot(ArcaneMcpParams.appUri));
      expect(ArcaneMcpParams.name, isNot(ArcaneMcpMethods.ping));
    });
  });

  group("envelope builders", () {
    test("arcaneMcpBuildResult nests the payload under result", () {
      const Map<String, Object?> payload = <String, Object?>{"mode": "light"};
      expect(
        arcaneMcpBuildResult(payload),
        <String, Object?>{"type": "result", "result": payload},
      );
    });

    test("arcaneMcpBuildResult carries a null payload", () {
      expect(
        arcaneMcpBuildResult(null),
        <String, Object?>{"type": "result", "result": null},
      );
    });

    test("arcaneMcpBuildError nests the message under error", () {
      const String message = "Something broke.";
      expect(
        arcaneMcpBuildError(message),
        <String, Object?>{"type": "error", "error": message},
      );
    });
  });
}
