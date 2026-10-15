import "dart:io" as io;

import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:dart_mcp/stdio.dart";

void main(List<String> args) async {
  final server = ArcaneMcpServer(
    stdioChannel(
      input: io.stdin,
      output: io.stdout,
    ),
  );

  if (args.contains("--http")) {
    await server.serveHttp();
  }
}
