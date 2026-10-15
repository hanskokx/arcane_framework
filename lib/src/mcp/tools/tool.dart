import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:dart_mcp/server.dart";

abstract class McpTool {
  Tool get tool;
  Future<CallToolResult> handler(
    CallToolRequest request,
    ArcaneAppConnection? connection,
    ArcaneMcpServer server,
  );
}
