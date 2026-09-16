import "dart:io";

import "package:arcane_framework/src/skills/register_skills.dart";
import "package:test/test.dart";

/// A temporary skills tree with the three shipped skills.
Future<String> _makeSource() async {
  final Directory dir = await Directory.systemTemp.createTemp("skills_src_");
  addTearDown(() => dir.delete(recursive: true));
  for (final String name in <String>[
    "arcane-framework-dev",
    "arcane-devtools-extension",
    "arcane-mcp-server",
  ]) {
    final Directory skill = Directory("${dir.path}/$name");
    await skill.create();
    await File("${skill.path}/SKILL.md").writeAsString(
      "---\nname: $name\n---\n\n# $name\n",
    );
  }
  return dir.path;
}

void main() {
  late String source;

  setUp(() async {
    source = await _makeSource();
  });

  group("skillTargets and roots", () {
    test("exposes both standard targets", () {
      expect(skillTargets, containsAll(<String>["opencode", "claude"]));
    });
  });

  group("registerSkills", () {
    test("installs every skill into the requested targets", () async {
      final Directory home = await Directory.systemTemp.createTemp("home_");
      addTearDown(() => home.delete(recursive: true));
      final SkillsRegisterResult result = await registerSkills(
        sourceDir: source,
        homeDir: home.path,
      );
      expect(result.errors, isEmpty);
      expect(result.installs, hasLength(6));
      final List<File> installed = <File>[
        File("${home.path}/.agents/skills/arcane-framework-dev/SKILL.md"),
        File("${home.path}/.agents/skills/arcane-devtools-extension/SKILL.md"),
        File("${home.path}/.agents/skills/arcane-mcp-server/SKILL.md"),
        File("${home.path}/.claude/skills/arcane-framework-dev/SKILL.md"),
        File("${home.path}/.claude/skills/arcane-devtools-extension/SKILL.md"),
        File("${home.path}/.claude/skills/arcane-mcp-server/SKILL.md"),
      ];
      for (final File file in installed) {
        expect(file.existsSync(), isTrue);
      }
    });

    test("copies supporting files alongside SKILL.md", () async {
      final File extra = File("$source/arcane-mcp-server/example.json");
      await extra.writeAsString('{"ok": true}');
      await Directory("$source/arcane-mcp-server/snippets").create();
      await File("$source/arcane-mcp-server/snippets/prompt.txt").writeAsString(
        "connect first\n",
      );
      final Directory home = await Directory.systemTemp.createTemp("home_");
      addTearDown(() => home.delete(recursive: true));
      await registerSkills(
        sourceDir: source,
        homeDir: home.path,
        targets: const <String>[opencodeTarget],
      );
      final File copied = File(
        "${home.path}/.agents/skills/arcane-mcp-server/example.json",
      );
      expect(copied.existsSync(), isTrue);
      expect(await copied.readAsString(), '{"ok": true}');
      final File nested = File(
        "${home.path}/.agents/skills/arcane-mcp-server/snippets/prompt.txt",
      );
      expect(await nested.readAsString(), "connect first\n");
    });

    test(
      "flags planned installs without writing anything in dry-run",
      () async {
        final Directory home = await Directory.systemTemp.createTemp("home_");
        addTearDown(() => home.delete(recursive: true));
        final SkillsRegisterResult result = await registerSkills(
          sourceDir: source,
          homeDir: home.path,
          dryRun: true,
        );
        expect(result.errors, isEmpty);
        expect(result.installs, hasLength(6));
        expect(result.installs.every((SkillInstall i) => i.dryRun), isTrue);
        expect(
          Directory("${home.path}/.agents/skills").existsSync(),
          isFalse,
        );
      },
    );

    test("reports an unknown target", () async {
      final Directory home = await Directory.systemTemp.createTemp("home_");
      addTearDown(() => home.delete(recursive: true));
      final SkillsRegisterResult result = await registerSkills(
        sourceDir: source,
        homeDir: home.path,
        targets: const <String>["copilot"],
      );
      expect(result.installs, isEmpty);
      expect(
        result.errors.single,
        contains(
          "Unknown target 'copilot' "
          "(expected one of opencode, claude).",
        ),
      );
    });

    test("reports a missing source directory", () async {
      final Directory home = await Directory.systemTemp.createTemp("home_");
      addTearDown(() => home.delete(recursive: true));
      final SkillsRegisterResult result = await registerSkills(
        sourceDir: "/definitely/not/here",
        homeDir: home.path,
      );
      expect(result.installs, isEmpty);
      expect(result.errors.single, contains("does not exist"));
    });

    test("reports skills with invalid names or missing SKILL.md", () async {
      final Directory home = await Directory.systemTemp.createTemp("home_");
      addTearDown(() => home.delete(recursive: true));
      await Directory("$source/UPPER_CASE").create();
      await Directory("$source/no-skill-file").create();
      final SkillsRegisterResult result = await registerSkills(
        sourceDir: source,
        homeDir: home.path,
      );
      expect(result.installs, hasLength(6));
      expect(
        result.errors.where(
          (String error) => error.contains("'UPPER_CASE'"),
        ),
        isNotEmpty,
      );
      expect(
        result.errors.where(
          (String error) => error.contains("'no-skill-file'"),
        ),
        isNotEmpty,
      );
      final String messages = result.errors.join("\n");
      expect(messages, contains("skill names must be lowercase"));
      expect(messages, contains("missing SKILL.md"));
    });
  });
}
