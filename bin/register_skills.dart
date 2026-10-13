import "dart:io";

import "package:arcane_framework/src/skills/register_skills.dart";
import "package:arcane_framework/src/skills/register_skills_cli.dart";

/// Installs the skills shipped with arcane_framework into agent skill roots.
///
/// Usage:
///   dart run arcane_framework:register_skills [--target opencode|claude]... [--home <dir>]
///     [--source <dir>] [--dry-run]
///
/// With no arguments it installs into both opencode (`~/.agents/skills`) and
/// Claude (`~/.claude/skills`), using the `skills/` directory next to this
/// package.
Future<void> main(List<String> arguments) async {
  final SkillsCliResult parsed = parseSkillsArgs(arguments);
  if (parsed.help) {
    stdout.writeln(skillsCliUsage());
    exit(0);
  }
  if (parsed.errors.isNotEmpty) {
    for (final String error in parsed.errors) {
      stderr.writeln("error: $error");
    }
    stdout.writeln(skillsCliUsage());
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
