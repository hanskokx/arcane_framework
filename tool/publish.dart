import "dart:convert";
import "dart:io";

/// Publishes [arcane_framework] to pub.dev, gating the publish on a fresh
/// build of the DevTools extension.
///
/// Before publishing, the script:
///  1. ensures the extension repo exists and is up to date,
///  2. rebuilds `extension/devtools/build/` from the extension source,
///  3. validates the extension contents,
///  4. and only then runs `flutter pub publish`.
///
/// Usage:
///   dart run tool/publish.dart [--dry-run] [--extension-path=<dir>]
///       [--extension-git-url=<url>]
///
/// Pass `--dry-run` to rebuild, validate, and run `flutter pub publish
/// --dry-run` without uploading the package.
Future<void> main(List<String> args) async {
  try {
    final PublishOptions options = _parseOptions(args);
    final String frameworkRoot = Directory.current.path;
    final String extensionRoot = _extensionRoot(options, frameworkRoot);

    await _ensureExtensionRepo(extensionRoot, options.extensionGitUrl);

    final bool overrideWritten = _writeFrameworkOverride(
      extensionRoot: extensionRoot,
      frameworkRoot: frameworkRoot,
    );

    try {
      await _cleanWorkspace(
        frameworkRoot: frameworkRoot,
      );

      await _buildExtension(
        extensionRoot: extensionRoot,
        frameworkRoot: frameworkRoot,
      );
      _assertPublishAssets(frameworkRoot);
      await _publish(
        frameworkRoot: frameworkRoot,
        dryRun: options.dryRun,
      );
    } finally {
      if (overrideWritten) {
        _deleteOverride(extensionRoot);
      }
    }
  } on _ScriptException {
    // The error was already reported; exit with the recorded status.
    exit(exitCode);
  }
}

class PublishOptions {
  const PublishOptions({
    required this.dryRun,
    required this.extensionPath,
    required this.extensionGitUrl,
  });

  final bool dryRun;
  final String? extensionPath;
  final String? extensionGitUrl;
}

PublishOptions _parseOptions(List<String> args) {
  bool dryRun = false;
  String? extensionPath;
  String? extensionGitUrl;

  for (final String arg in args) {
    if (arg == "--dry-run") {
      dryRun = true;
    } else if (arg.startsWith("--extension-path=")) {
      extensionPath = arg.substring("--extension-path=".length);
    } else if (arg.startsWith("--extension-git-url=")) {
      extensionGitUrl = arg.substring("--extension-git-url=".length);
    } else {
      throw _usageError(arg);
    }
  }

  return PublishOptions(
    dryRun: dryRun,
    extensionPath: extensionPath,
    extensionGitUrl: extensionGitUrl,
  );
}

String _extensionRoot(PublishOptions options, String frameworkRoot) {
  final String? configured = options.extensionPath;
  if (configured == null) {
    return _join(
      _join(frameworkRoot, ".."),
      "arcane_framework_devtools_extension",
    );
  }
  return _absolute(configured);
}

Future<void> _ensureExtensionRepo(String extensionRoot, String? gitUrl) async {
  final Directory repo = Directory(extensionRoot);
  if (!repo.existsSync()) {
    if (gitUrl == null) {
      _fail(
        "Extension repo not found at $extensionRoot.\n"
        "Clone it first or pass --extension-git-url=<url> to clone automatically.",
      );
    }
    _log("Cloning extension repo into $extensionRoot...");
    final (int code, String output) = await _runCaptured([
      "git",
      "clone",
      gitUrl,
      extensionRoot,
    ], Directory.current.path);
    if (code != 0) {
      _fail("Failed to clone the extension repo:\n$output");
    }
    return;
  }

  _log("Verifying the extension repo at $extensionRoot is up to date...");
  final (int statusCode, String statusOutput) = await _runCaptured([
    "git",
    "-C",
    extensionRoot,
    "status",
    "--porcelain",
  ], Directory.current.path);
  if (statusCode != 0) {
    _warn("Could not inspect git status of the extension repo.");
  } else if (statusOutput.trim().isNotEmpty) {
    _warn("The extension repo has uncommitted changes; proceeding anyway.");
  }

  final (int remoteCode, _) = await _runCaptured([
    "git",
    "-C",
    extensionRoot,
    "remote",
    "get-url",
    "origin",
  ], Directory.current.path);
  if (remoteCode != 0) {
    _warn(
      "The extension repo has no 'origin' remote; skipping the update check.",
    );
    return;
  }

  final (int fetchCode, String fetchOutput) = await _runCaptured([
    "git",
    "-C",
    extensionRoot,
    "fetch",
    "origin",
  ], Directory.current.path);
  if (fetchCode != 0) {
    _warn("Could not fetch the extension repo:\n$fetchOutput");
    return;
  }

  final (int pullCode, String pullOutput) = await _runCaptured([
    "git",
    "-C",
    extensionRoot,
    "pull",
    "--ff-only",
  ], Directory.current.path);
  if (pullCode != 0) {
    _warn("Could not fast-forward the extension repo:\n$pullOutput");
  }
}

/// Writes a `pubspec_overrides.yaml` in the extension repo that points
/// `arcane_framework` at the local checkout, so the build resolves even before
/// the framework is published to pub.dev. Returns whether the script wrote it.
bool _writeFrameworkOverride({
  required String extensionRoot,
  required String frameworkRoot,
}) {
  final File overrideFile = File(
    _join(extensionRoot, "pubspec_overrides.yaml"),
  );
  if (overrideFile.existsSync()) {
    _warn(
      "An existing pubspec_overrides.yaml is present in the extension repo; "
      "leaving it untouched.",
    );
    return false;
  }

  overrideFile.writeAsStringSync(
    "dependency_overrides:\n"
    "  arcane_framework:\n"
    "    path: $frameworkRoot\n",
  );
  _log("Wrote a temporary pubspec_overrides.yaml in the extension repo.");
  return true;
}

void _deleteOverride(String extensionRoot) {
  final File overrideFile = File(
    _join(extensionRoot, "pubspec_overrides.yaml"),
  );
  if (overrideFile.existsSync()) {
    overrideFile.deleteSync();
    _log(
      "Removed the temporary pubspec_overrides.yaml from the extension repo.",
    );
  }
}

Future<void> _cleanWorkspace({
  required String frameworkRoot,
}) async {
  _log("Cleaning workspace...");
  final (int cleanCode, String cleanOutput) = await _runCaptured([
    _flutterBinary(),
    "clean",
  ], frameworkRoot);
  if (cleanCode != 0) {
    _fail("flutter clean failed:\n$cleanOutput");
  }

  _log("Cleaning build...");
  final (int buildCode, String buildOutput) = await _runCaptured([
    _flutterBinary(),
    "clean",
    "build",
  ], frameworkRoot);
  if (buildCode != 0) {
    _fail("flutter clean build failed:\n$buildOutput");
  }
}

Future<void> _buildExtension({
  required String extensionRoot,
  required String frameworkRoot,
}) async {
  final String dest = _join(_join(frameworkRoot, "extension"), "devtools");

  _log("Installing extension dependencies...");
  final (int pubGetCode, String pubGetOutput) = await _runCaptured([
    _flutterBinary(),
    "pub",
    "get",
  ], extensionRoot);
  if (pubGetCode != 0) {
    _fail("flutter pub get failed in the extension repo:\n$pubGetOutput");
  }

  _log(
    "Building the extension web app and copying it into arcane_framework...",
  );
  final (int buildCode, String buildOutput) = await _runCaptured([
    "dart",
    "run",
    "devtools_extensions",
    "build_and_copy",
    "--source=.",
    "--dest=$dest",
  ], extensionRoot);
  if (buildCode != 0) {
    _fail("Extension build failed:\n$buildOutput");
  }

  _log("Validating the extension contents...");
  final (int validateCode, String validateOutput) = await _runCaptured([
    "dart",
    "run",
    "devtools_extensions",
    "validate",
    "--package=$frameworkRoot",
  ], extensionRoot);
  if (validateCode != 0) {
    _fail("Extension validation failed:\n$validateOutput");
  }
}

void _assertPublishAssets(String frameworkRoot) {
  final String devtoolsDir = _join(
    _join(frameworkRoot, "extension"),
    "devtools",
  );

  final File pubIgnore = File(_join(devtoolsDir, ".pubignore"));
  if (!pubIgnore.existsSync()) {
    _fail(
      "Missing $devtoolsDir/.pubignore.\n"
      "Add one containing '!build' so the compiled extension ships on pub.dev.",
    );
  }
  final String pubIgnoreContents = pubIgnore.readAsStringSync();
  if (!pubIgnoreContents.contains("!build")) {
    _fail(
      "extension/devtools/.pubignore does not contain '!build'.\n"
      "Without it, the (gitignored) build directory would be omitted from the "
      "published archive.",
    );
  }

  final Directory buildDir = Directory(_join(devtoolsDir, "build"));
  if (!buildDir.existsSync() || buildDir.listSync().isEmpty) {
    _fail(
      "extension/devtools/build/ is missing or empty.\n"
      "Run this script again after the extension build completes.",
    );
  }
}

Future<void> _publish({
  required String frameworkRoot,
  required bool dryRun,
}) async {
  if (dryRun) {
    _log("Running 'flutter pub publish --dry-run' (no upload)...");
  } else {
    _log("Publishing arcane_framework to pub.dev...");
  }

  final (int code, String output) = await _runCaptured([
    _flutterBinary(),
    "pub",
    "publish",
    if (dryRun) ...["--dry-run", "--ignore-warnings"],
  ], frameworkRoot);
  if (code != 0) {
    _fail("flutter pub publish failed:\n$output");
  }

  if (dryRun) {
    _log("Dry run complete. Nothing was uploaded.\n$output");
  } else {
    _log("arcane_framework published successfully.\n$output");
  }
}

String _flutterBinary() => Platform.isWindows ? "flutter.bat" : "flutter";

Future<(int, String)> _runCaptured(
  List<String> command,
  String workingDirectory,
) async {
  final ProcessResult result = await Process.run(
    command.first,
    command.sublist(1),
    workingDirectory: workingDirectory,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final String stdout = result.stdout as String? ?? "";
  final String stderr = result.stderr as String? ?? "";
  final String stderrTrimmed = stderr.trim();
  if (stderrTrimmed.isEmpty) {
    return (result.exitCode, stdout);
  }
  return (result.exitCode, "$stderrTrimmed\n\n---\n\n$stdout");
}

Never _fail(String message) {
  stderr.writeln("Error: $message");
  exitCode = 1;
  throw _ScriptException();
}

/// Marks a fatal condition in the script; the message is printed by [_fail]
/// or [_usageError] before this is thrown.
class _ScriptException implements Exception {}

void _log(String message) => stdout.writeln("[publish] $message");

void _warn(String message) => stderr.writeln("[publish] Warning: $message");

String _join(String parent, String child) {
  final String separator = Platform.pathSeparator;
  if (parent.endsWith(separator)) {
    return "$parent$child";
  }
  return "$parent$separator$child";
}

String _absolute(String path) {
  final String resolved = Directory(path).absolute.path;
  return resolved.endsWith(Platform.pathSeparator)
      ? resolved.substring(0, resolved.length - 1)
      : resolved;
}

Never _usageError(String unknownArg) {
  stderr.writeln(
    "Unknown argument: $unknownArg\n"
    "Usage: dart run tool/publish.dart [--dry-run] "
    "[--extension-path=<dir>] [--extension-git-url=<url>]",
  );
  exitCode = 64;
  throw _ScriptException();
}
