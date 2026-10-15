import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:arcane_framework/src/mcp/tools/tool.dart";
import "package:dart_mcp/server.dart";

class ConnectTool extends McpTool {
  @override
  Tool get tool => Tool(
    name: "connect_app",
    description:
        "Connect to a running arcane_framework app using its VM service URI.",
    inputSchema: Schema.object(
      properties: {
        "appUri": Schema.string(
          description: "The VM service URI of the app to connect to.",
        ),
        "appName": Schema.string(
          description: "The human-readable name of the app.",
        ),
      },
    ),
  );

  @override
  Future<CallToolResult> handler(
    CallToolRequest request,
    ArcaneAppConnection? connection,
    ArcaneMcpServer server,
  ) async {
    if (connection != null) {
      return CallToolResult(
        content: [TextContent(text: "Already connected to ${connection.name}")],
      );
    }

    final String? appUriStr = request.arguments?["appUri"] as String?;
    if (appUriStr == null) {
      return CallToolResult(
        content: [TextContent(text: "Missing appUri")],
        isError: true,
      );
    }

    final Uri uri = Uri.parse(appUriStr);
    try {
      final newConnection = await VmServiceArcaneAppConnection.connect(
        uri,
        name: request.arguments?["appName"] as String?,
      );
      await server.connect(newConnection);
      return CallToolResult(
        content: [
          TextContent(text: "Successfully connected to ${newConnection.name}"),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [TextContent(text: e.toString())],
        isError: true,
      );
    }
  }
}
