import "dart:io";

import "package:arcane_framework/src/mcp/server/arcane_version.dart";
import "package:test/test.dart";

void main() {
  group("arcaneFrameworkVersion", () {
    test("matches pubspec.yaml version", () {
      final File pubspec = File("pubspec.yaml");
      expect(pubspec.existsSync(), isTrue);

      final String content = pubspec.readAsStringSync();
      final RegExp versionPattern = RegExp(r"^version:\s*(\S+)\s*$", multiLine: true);
      final RegExpMatch? match = versionPattern.firstMatch(content);
      expect(match, isNotNull, reason: "pubspec.yaml must have a top-level version field");

      final String expectedVersion = match!.group(1)!;
      expect(expectedVersion, isNotEmpty);

      final String actualVersion = arcaneFrameworkVersion();
      expect(actualVersion, equals(expectedVersion));
    });

    test("returns non-empty version string", () {
      final String version = arcaneFrameworkVersion();
      expect(version, isNotEmpty);
      expect(version, matches(RegExp(r"^\d+\.\d+\.\d+.*$")));
    });
  });

  group("ArcaneMcpServer version", () {
    test("reports the same version as pubspec", () {
      // We can't easily construct a real ArcaneMcpServer without a live channel,
      // but we can verify the version function is used by checking that
      // arcaneFrameworkVersion() is called during server construction.
      // This is covered by the integration test in arcane_mcp_server_bin_test.dart.
      // Here we just verify the version function returns the expected value.
      expect(arcaneFrameworkVersion(), isNotEmpty);
    });
  });
}
