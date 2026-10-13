import "package:arcane_framework/src/skills/register_skills_cli.dart";
import "package:test/test.dart";

void main() {
  group("parseSkillsArgs", () {
    test("--help sets help flag", () {
      final SkillsCliResult result = parseSkillsArgs(["--help"]);
      expect(result.help, isTrue);
      expect(result.errors, isEmpty);
    });

    test("-h sets help flag", () {
      final SkillsCliResult result = parseSkillsArgs(["-h"]);
      expect(result.help, isTrue);
      expect(result.errors, isEmpty);
    });

    test("--target with valid value adds target", () {
      final SkillsCliResult result = parseSkillsArgs(["--target", "opencode"]);
      expect(result.targets, equals(["opencode"]));
      expect(result.errors, isEmpty);
    });

    test("--target with invalid value produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["--target", "invalid"]);
      expect(result.targets, isEmpty);
      expect(
        result.errors,
        contains("--target must be one of opencode, claude; got 'invalid'."),
      );
    });

    test("--target with missing value produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["--target"]);
      expect(result.targets, isEmpty);
      expect(result.errors, contains("--target requires a value."));
    });

    test("--target repeated accumulates targets", () {
      final SkillsCliResult result = parseSkillsArgs([
        "--target",
        "opencode",
        "--target",
        "claude",
      ]);
      expect(result.targets, equals(["opencode", "claude"]));
      expect(result.errors, isEmpty);
    });

    test("--home with value sets home", () {
      final SkillsCliResult result = parseSkillsArgs(["--home", "/some/path"]);
      expect(result.home, equals("/some/path"));
      expect(result.errors, isEmpty);
    });

    test("--home with missing value produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["--home"]);
      expect(result.home, isNull);
      expect(result.errors, contains("--home requires a path."));
    });

    test("--source with value sets source", () {
      final SkillsCliResult result = parseSkillsArgs([
        "--source",
        "/some/path",
      ]);
      expect(result.source, equals("/some/path"));
      expect(result.errors, isEmpty);
    });

    test("--source with missing value produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["--source"]);
      expect(result.source, isNull);
      expect(result.errors, contains("--source requires a path."));
    });

    test("--dry-run sets dryRun", () {
      final SkillsCliResult result = parseSkillsArgs(["--dry-run"]);
      expect(result.dryRun, isTrue);
      expect(result.errors, isEmpty);
    });

    test("-n sets dryRun", () {
      final SkillsCliResult result = parseSkillsArgs(["-n"]);
      expect(result.dryRun, isTrue);
      expect(result.errors, isEmpty);
    });

    test("no args defaults to both targets", () {
      final SkillsCliResult result = parseSkillsArgs([]);
      expect(result.targets, equals(["opencode", "claude"]));
      expect(result.errors, isEmpty);
    });

    test("unknown option produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["--bogus"]);
      expect(result.errors, contains("Unknown option '--bogus'."));
    });

    test("stray positional produces error", () {
      final SkillsCliResult result = parseSkillsArgs(["somearg"]);
      expect(result.errors, contains("Unknown argument 'somearg'."));
    });

    test("usage mentions executable and all flags", () {
      final String usage = skillsCliUsage();
      expect(usage, contains("dart run arcane_framework:register_skills"));
      expect(usage, contains("--target"));
      expect(usage, contains("--home"));
      expect(usage, contains("--source"));
      expect(usage, contains("--dry-run, -n"));
      expect(usage, contains("--help, -h"));
    });
  });
}
