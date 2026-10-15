import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/mcp/tools/extension_tool.dart";
import "package:dart_mcp/server.dart";

class LogTool extends ExtensionTool {
  LogTool() : super(ArcaneMcpMethods.logs);

  @override
  Tool get tool => Tool(
    name: "get_logs",
    description: "Get the latest log entries.",
    inputSchema: Schema.object(
      properties: {
        "level": Schema.string(
          description: "A minimum log level name",
        ),
        "module": Schema.string(
          description: "A module-name filter",
        ),
        "search": Schema.string(
          description: "A message search string",
        ),
        "limit": Schema.int(
          description: "The maximum number of log entries",
        ),
      },
    ),
  );
}
