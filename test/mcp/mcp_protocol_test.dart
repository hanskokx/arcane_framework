import "dart:convert";

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

  group("codec", () {
    test("arcaneMcpBuildResult round-trips", () {
      const Map<String, Object?> payload = <String, Object?>{"mode": "light"};
      final ArcaneMcpResponse response = arcaneMcpDecode(
        jsonEncode(arcaneMcpBuildResult(payload)),
      );
      expect(
        response,
        isA<ArcaneMcpOkResponse>().having(
          (ArcaneMcpOkResponse r) => r.data,
          "data",
          payload,
        ),
      );
    });

    test("arcaneMcpBuildError round-trips", () {
      const String message = "Something broke.";
      final ArcaneMcpResponse response = arcaneMcpDecode(
        jsonEncode(arcaneMcpBuildError(message)),
      );
      expect(
        response,
        isA<ArcaneMcpErrorResponse>().having(
          (ArcaneMcpErrorResponse r) => r.message,
          "message",
          message,
        ),
      );
    });

    test("decode rejects a body that is not JSON", () {
      final ArcaneMcpResponse response = arcaneMcpDecode("not json");
      expect(response, isA<ArcaneMcpErrorResponse>());
    });

    test("decode rejects a body that is not a JSON object", () {
      final ArcaneMcpResponse response = arcaneMcpDecode("[1, 2, 3]");
      expect(response, isA<ArcaneMcpErrorResponse>());
    });

    test("decode rejects an unknown response type", () {
      final ArcaneMcpResponse response = arcaneMcpDecode(
        '{"type": "wat", "result": {}}',
      );
      expect(response, isA<ArcaneMcpErrorResponse>());
    });
  });
}
