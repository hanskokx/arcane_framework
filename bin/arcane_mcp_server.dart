import "dart:io";

import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:dart_mcp/stdio.dart";

/// Runs the standalone arcane_framework MCP server over stdio.
///
/// It speaks the Model Context Protocol over stdio, discovers running Flutter
/// apps through the Dart Tooling Daemon, connects to an app's VM service, and
/// calls the [arcaneMcpServiceExtension] extension that arcane_framework
/// registers when an app mounts `ArcaneApp`.
Future<void> main() async {
  final ArcaneMcpServer server = ArcaneMcpServer(
    stdioChannel(input: stdin, output: stdout),
  );
  await server.initialized;
  await server.done;
}
