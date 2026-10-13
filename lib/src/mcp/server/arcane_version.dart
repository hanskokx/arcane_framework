/// The version arcane_framework declares in its pubspec.yaml.
///
/// Reads the package's pubspec.yaml through the package config; there is
/// deliberately no compiled-in fallback, so the MCP handshake can never
/// advertise a stale version.
///
/// Throws a [StateError] when the package's pubspec.yaml cannot be located,
/// read, or parsed.
library;

import "dart:io";

import "dart:isolate";

/// Returns the version declared in this package's pubspec.yaml.
///
/// Locates the package root via [Isolate.resolvePackageUriSync] so the lookup
/// works for `dart run`, `dart pub global run`, and when
/// [ArcaneMcpServer] is embedded in a host Flutter app (as documented in
/// `skills/arcane-mcp-server/SKILL.md`).
///
/// The located pubspec is validated to contain `name: arcane_framework` so a
/// host application's pubspec can never be mistaken for ours.
///
/// If the pubspec cannot be found, read, or parsed, a [StateError] is thrown
/// with an actionable message rather than silently reporting a wrong version.
String arcaneFrameworkVersion() {
  final Uri? packageRootUri = Isolate.resolvePackageUriSync(
    Uri.parse("package:arcane_framework/arcane_framework.dart"),
  );
  if (packageRootUri == null) {
    throw StateError(
      "Could not resolve arcane_framework package URI. "
      "This typically means the application was compiled with `dart compile exe`, "
      "which does not include package configuration. "
      "Run the server via `dart run arcane_framework:arcane_mcp_server` instead.",
    );
  }

  final File packageFile = File.fromUri(packageRootUri);
  Directory current = packageFile.parent;
  File? pubspecFile;

  while (true) {
    final File candidate = File(
      "${current.path}${Platform.pathSeparator}pubspec.yaml",
    );
    if (candidate.existsSync()) {
      pubspecFile = candidate;
      break;
    }
    final Directory parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }

  if (pubspecFile == null) {
    throw StateError(
      "Could not locate pubspec.yaml for arcane_framework. "
      "Resolved package root: ${packageFile.parent.path}. "
      "Ensure the package is installed with its source (not a compiled snapshot).",
    );
  }

  final String pubspecContent = pubspecFile.readAsStringSync();

  // Validate this is actually our package.
  final RegExp namePattern = RegExp(
    r"^name:\s*arcane_framework\b",
    multiLine: true,
  );
  if (!namePattern.hasMatch(pubspecContent)) {
    throw StateError(
      "Located pubspec.yaml does not declare 'name: arcane_framework'. "
      "File: ${pubspecFile.path}. "
      "This indicates a mismatch between the resolved package and the expected one.",
    );
  }

  // Parse the version field (top-level, unindented).
  final RegExp versionPattern = RegExp(
    r"^version:\s*(\S+)\s*$",
    multiLine: true,
  );
  final RegExpMatch? match = versionPattern.firstMatch(pubspecContent);
  if (match == null) {
    throw StateError(
      "Could not parse 'version:' from pubspec.yaml at ${pubspecFile.path}. "
      "Content preview: ${pubspecContent.split('\n').take(10).join('\n')}...",
    );
  }

  return match.group(1)!;
}
