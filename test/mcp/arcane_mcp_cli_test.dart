import "package:arcane_framework/src/mcp/server/arcane_mcp_cli.dart";
import "package:test/test.dart";

void main() {
  group("parseArcaneMcpArgs", () {
    test("--help sets help flag", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["--help"]);
      expect(result.help, isTrue);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isFalse);
      expect(result.errors, isEmpty);
    });

    test("-h sets help flag", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["-h"]);
      expect(result.help, isTrue);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isFalse);
      expect(result.errors, isEmpty);
    });

    test("--version sets version flag", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["--version"]);
      expect(result.help, isFalse);
      expect(result.showVersion, isTrue);
      expect(result.runServer, isFalse);
      expect(result.errors, isEmpty);
    });

    test("no args runs server", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs([]);
      expect(result.help, isFalse);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isTrue);
      expect(result.errors, isEmpty);
    });

    test("unknown option produces error", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["--bogus"]);
      expect(result.help, isFalse);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isFalse);
      expect(result.errors, contains("Unknown option '--bogus'."));
    });

    test("stray positional produces error", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["somearg"]);
      expect(result.help, isFalse);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isFalse);
      expect(result.errors, contains("Unknown argument 'somearg'."));
    });

    test("-- stops parsing", () {
      final ArcaneMcpCliResult result = parseArcaneMcpArgs(["--", "--bogus"]);
      expect(result.help, isFalse);
      expect(result.showVersion, isFalse);
      expect(result.runServer, isTrue);
      expect(result.errors, isEmpty);
    });

    test("usage mentions executable and both flags", () {
      final String usage = arcaneMcpUsage();
      expect(usage, contains("dart run arcane_framework:arcane_mcp_server"));
      expect(usage, contains("--help, -h"));
      expect(usage, contains("--version"));
    });
  });
}
