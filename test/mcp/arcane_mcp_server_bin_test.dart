import "dart:io";

import "package:test/test.dart";

void main() {
  final String dartExecutable = Platform.resolvedExecutable;
  const String binPath = "bin/arcane_mcp_server.dart";

  group("arcane_mcp_server binary", () {
    test("--help exits 0 with usage banner", () async {
      final ProcessResult result = await Process.run(
        dartExecutable,
        ["run", binPath, "--help"],
        runInShell: false,
      );
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains("Usage: dart run arcane_framework:arcane_mcp_server"),
      );
      expect(result.stdout.toString(), contains("--help, -h"));
      expect(result.stdout.toString(), contains("--version"));
      expect(result.stderr, isEmpty);
    });

    test("--version exits 0 with non-empty version", () async {
      final ProcessResult result = await Process.run(
        dartExecutable,
        ["run", binPath, "--version"],
        runInShell: false,
      );
      expect(result.exitCode, equals(0));
      final String version = result.stdout.toString().trim();
      expect(version, isNotEmpty);
      expect(version, matches(RegExp(r"^\d+\.\d+\.\d+")));
      expect(result.stderr, isEmpty);
    });

    test("--bogus exits 64 with error to stderr", () async {
      final ProcessResult result = await Process.run(
        dartExecutable,
        ["run", binPath, "--bogus"],
        runInShell: false,
      );
      expect(result.exitCode, equals(64));
      expect(result.stderr.toString(), contains("Unknown option '--bogus'."));
      expect(
        result.stdout.toString(),
        contains("Usage: dart run arcane_framework:arcane_mcp_server"),
      );
    });
  });
}
