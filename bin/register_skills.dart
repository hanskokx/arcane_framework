import "dart:io";

import "package:arcane_framework/src/skills/register_skills.dart";

/// Installs the skills shipped with arcane_framework into agent skill roots.
///
/// Usage:
///   dart run register_skills [--target opencode|claude]... [--home <dir>]
///     [--source <dir>] [--dry-run]
///
/// With no arguments it installs into both opencode (`~/.agents/skills`) and
/// Claude (`~/.claude/skills`), using the `skills/` directory next to this
/// package.
Future<void> main(List<String> arguments) async {
  final ParseResult parsed = _parse(arguments);
  if (parsed.help) {
    _printUsage();
    exit(0);
  }
  if (parsed.errors.isNotEmpty) {
    for (final String error in parsed.errors) {
      stderr.writeln("error: $error");
    }
    _printUsage();
    exit(64);
  }

  final String source = parsed.source ?? _packageSkillsDir();
  final String home = parsed.home ?? Platform.environment["HOME"] ?? "";
  if (home.isEmpty) {
    stderr.writeln(
      "error: could not determine the home directory; pass "
      "--home.",
    );
    exit(64);
  }

  final SkillsRegisterResult result = await registerSkills(
    sourceDir: source,
    homeDir: home,
    targets: parsed.targets,
    dryRun: parsed.dryRun,
  );

  for (final String error in result.errors) {
    stderr.writeln("warning: $error");
  }
  for (final SkillInstall install in result.installs) {
    stdout.writeln(
      "${install.dryRun ? "would " : ""}${install.target}: "
      "${install.name} -> ${install.destination}",
    );
  }
  if (result.installs.isEmpty) {
    stderr.writeln("error: no skills installed.");
    exit(1);
  }
}

/// The parsed command line.
class ParseResult {
  const ParseResult({
    this.targets = const <String>[opencodeTarget, claudeTarget],
    this.home,
    this.source,
    this.dryRun = false,
    this.help = false,
    this.errors = const <String>[],
  });

  final List<String> targets;
  final String? home;
  final String? source;
  final bool dryRun;
  final bool help;
  final List<String> errors;
}

ParseResult _parse(List<String> arguments) {
  final List<String> targets = <String>[];
  final List<String> errors = <String>[];
  String? home;
  String? source;
  bool dryRun = false;
  bool help = false;
  for (int i = 0; i < arguments.length; i++) {
    final String argument = arguments[i];
    switch (argument) {
      case "--dry-run":
      case "-n":
        dryRun = true;
      case "--help":
      case "-h":
        help = true;
      case "--home":
        home = _value(arguments, ++i);
        if (home == null) {
          errors.add("--home requires a path.");
        }
      case "--source":
        source = _value(arguments, ++i);
        if (source == null) {
          errors.add("--source requires a path.");
        }
      default:
        if (argument == "--target") {
          final String? target = _value(arguments, ++i);
          if (target == null || !skillTargets.contains(target)) {
            errors.add(
              "--target must be one of ${skillTargets.join(", ")}; got "
              "'$target'.",
            );
          } else {
            targets.add(target);
          }
        } else if (!argument.startsWith("-")) {
          errors.add("Unknown argument '$argument'.");
        } else {
          errors.add("Unknown option '$argument'.");
        }
    }
  }
  return ParseResult(
    targets:
        targets.isEmpty
            ? const <String>[opencodeTarget, claudeTarget]
            : targets,
    home: home,
    source: source,
    dryRun: dryRun,
    help: help,
    errors: errors,
  );
}

/// The value that follows a `--flag` pair, or null if missing.
String? _value(List<String> arguments, int index) {
  if (index >= arguments.length) return null;
  final String value = arguments[index];
  return value.startsWith("-") ? null : value;
}

/// The `skills/` directory inside this package (or empty when not found).
String _packageSkillsDir() {
  Directory current = File.fromUri(Platform.script).parent;
  while (true) {
    final Directory skills = Directory(
      "${current.path}${Platform.pathSeparator}skills",
    );
    if (skills.existsSync()) return skills.path;
    final Directory parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
  }
  return "skills";
}

void _printUsage() {
  stdout.writeln(
    "Usage: dart run register_skills [options]\n"
    "\n"
    "Installs the arcane_framework skills into agent skill roots.\n"
    "\n"
    "Options:\n"
    "  --target <opencode|claude>   Install for one target (repeatable).\n"
    "                               Defaults to both.\n"
    "  --home <dir>                 The user home directory to install under.\n"
    "                               Defaults to \$HOME.\n"
    "  --source <dir>               The directory containing the skills/ tree.\n"
    "                               Defaults to this package's skills/.\n"
    "  --dry-run, -n                Print what would be installed without\n"
    "                               writing anything.\n"
    "  --help, -h                   Show this help.\n",
  );
}
