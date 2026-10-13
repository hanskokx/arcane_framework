import "dart:io";

import "package:arcane_framework/src/mcp/server/arcane_mcp_cli.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:arcane_framework/src/mcp/server/arcane_version.dart";
import "package:dart_mcp/stdio.dart";

/// Runs the standalone arcane_framework MCP server over stdio.
///
/// It speaks the Model Context Protocol over stdio, discovers running Flutter
/// apps through the Dart Tooling Daemon, connects to an app's VM service, and
/// calls the [arcaneMcpServiceExtension] extension that arcane_framework
/// registers when an app mounts `ArcaneApp`.
Future<void> main(List<String> arguments) async {
  final ArcaneMcpCliResult parsed = parseArcaneMcpArgs(arguments);
  if (parsed.help) {
    stdout.writeln(arcaneMcpUsage());
    exit(0);
  }
  if (parsed.showVersion) {
    stdout.writeln(arcaneFrameworkVersion());
    exit(0);
  }
  if (parsed.errors.isNotEmpty) {
    for (final String error in parsed.errors) {
      stderr.writeln("error: $error");
    }
    stdout.writeln(arcaneMcpUsage());
    exit(64);
  }

  final ArcaneMcpServer server = ArcaneMcpServer(
    stdioChannel(input: stdin, output: stdout),
  );
  await server.initialized;
  await server.done;
}
