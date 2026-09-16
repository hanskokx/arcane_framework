/// Installs the skills shipped with arcane_framework into user skill roots.
///
/// Skills live in the package's `skills/` directory, one subdirectory per
/// skill (for example `skills/arcane-framework-dev/SKILL.md`). This library
/// copies each skill directory into the skill root an agent reads:
/// opencode reads `<home>/.agents/skills`, Claude Code reads
/// `<home>/.claude/skills`.
library;

import "dart:io";

/// The opencode target: skills are installed to `<home>/.agents/skills/*`.
const String opencodeTarget = "opencode";

/// The Claude Code target: skills are installed to `<home>/.claude/skills/*`.
const String claudeTarget = "claude";

/// The targets [registerSkills] knows how to install into.
const List<String> skillTargets = <String>[opencodeTarget, claudeTarget];

/// A single skill copied into a target's skill root.
class SkillInstall {
  /// Creates an install entry. [dryRun] marks a planned, not executed, copy.
  const SkillInstall({
    required this.target,
    required this.name,
    required this.destination,
    this.dryRun = false,
  });

  /// The target root the skill was installed into.
  final String target;

  /// The skill's directory name.
  final String name;

  /// The directory the skill was (or would be) copied to.
  final String destination;

  /// Whether this is a dry-run plan rather than an executed copy.
  final bool dryRun;
}

/// The outcome of a [registerSkills] call.
class SkillsRegisterResult {
  /// Creates a result from the executed installs and any [errors].
  const SkillsRegisterResult({
    required this.installs,
    required this.errors,
  });

  /// The skills that were copied (or planned, in dry-run mode).
  final List<SkillInstall> installs;

  /// Human-readable problems that did not stop the rest of the install.
  final List<String> errors;
}

/// Copies the skills under [sourceDir] into the skill roots of [targets].
///
/// [homeDir] is the user's home directory (`~`); skills land in
/// `.agents/skills` for opencode and `.claude/skills` for Claude. Each
/// skill is a subdirectory of [sourceDir] containing a `SKILL.md`. With
/// [dryRun] set to true nothing is written; [SkillInstall.dryRun] marks the
/// planned copies. Returns a [SkillsRegisterResult] describing what happened;
/// unknown targets and malformed skill directories are reported in
/// [SkillsRegisterResult.errors].
Future<SkillsRegisterResult> registerSkills({
  required String sourceDir,
  required String homeDir,
  List<String> targets = const <String>[opencodeTarget, claudeTarget],
  bool dryRun = false,
}) async {
  final List<SkillInstall> installs = <SkillInstall>[];
  final List<String> errors = <String>[];
  final Directory source = Directory(sourceDir);
  if (!await source.exists()) {
    return SkillsRegisterResult(
      installs: installs,
      errors: <String>["Source directory does not exist: $sourceDir"],
    );
  }

  for (final String target in targets) {
    final String? root = _skillRoot(homeDir, target);
    if (root == null) {
      errors.add(
        "Unknown target '$target' (expected one of "
        "${skillTargets.join(", ")}).",
      );
      continue;
    }
    for (final Directory skillDir in await _skillDirectories(source)) {
      final String name = skillDir.path.split(Platform.pathSeparator).last;
      if (!RegExp(r"^[a-z0-9-]+$").hasMatch(name)) {
        errors.add(
          "Skipped '$name': skill names must be lowercase "
          "letters, digits, and hyphens.",
        );
        continue;
      }
      final File skillFile = File(
        "${skillDir.path}${Platform.pathSeparator}"
        "SKILL.md",
      );
      if (!await skillFile.exists()) {
        errors.add("Skipped '$name': missing SKILL.md.");
        continue;
      }
      final String destination = "$root${Platform.pathSeparator}$name";
      installs.add(
        SkillInstall(
          target: target,
          name: name,
          destination: destination,
          dryRun: dryRun,
        ),
      );
      if (dryRun) continue;
      final Directory destinationDir = Directory(destination);
      await destinationDir.create(recursive: true);
      await _copyDirectory(skillDir, destinationDir);
    }
  }
  return SkillsRegisterResult(installs: installs, errors: errors);
}

/// The skill root directory for [target], or null for unknown targets.
String? _skillRoot(String homeDir, String target) {
  return switch (target) {
    opencodeTarget =>
      "$homeDir${Platform.pathSeparator}.agents"
          "${Platform.pathSeparator}skills",
    claudeTarget =>
      "$homeDir${Platform.pathSeparator}.claude"
          "${Platform.pathSeparator}skills",
    _ => null,
  };
}

/// The immediate subdirectories of [source] that look like skills.
Future<List<Directory>> _skillDirectories(Directory source) async {
  final List<Directory> directories = <Directory>[];
  await for (final FileSystemEntity entity in source.list()) {
    if (entity is Directory) directories.add(entity);
  }
  return directories;
}

/// Recursively copies the contents of [from] into [to].
Future<void> _copyDirectory(Directory from, Directory to) async {
  await for (final FileSystemEntity entity in from.list()) {
    if (entity is Directory) {
      final Directory target = Directory(
        "${to.path}${Platform.pathSeparator}${_basename(entity.path)}",
      );
      await target.create(recursive: true);
      await _copyDirectory(entity, target);
    } else if (entity is File) {
      final String destination =
          "${to.path}${Platform.pathSeparator}${_basename(entity.path)}";
      await File(destination).writeAsString(await entity.readAsString());
    }
  }
}

/// The final path segment of [path].
String _basename(String path) => path.split(Platform.pathSeparator).last;
