import "package:dart_mcp/server.dart";

abstract class McpTool {
  Tool get tool;
  CallToolResult handler(CallToolRequest request);
}
