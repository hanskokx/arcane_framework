import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:arcane_framework/src/mcp/tools/tool.dart";
import "package:dart_mcp/server.dart";

abstract class ExtensionTool extends McpTool {
  final String extensionMethod;

  ExtensionTool(this.extensionMethod);

  @override
  Future<CallToolResult> handler(
    CallToolRequest request,
    ArcaneAppConnection? connection,
    ArcaneMcpServer server,
  ) {
    if (connection == null) {
      throw Exception(
        "No active connection to an arcane_framework app. Please connect first.",
      );
    }
    return handleExtensionCall(request, connection);
  }

  Future<CallToolResult> handleExtensionCall(
    CallToolRequest request,
    ArcaneAppConnection connection,
  ) async {
    final ArcaneMcpResponse response = await connection.invoke(
      extensionMethod,
      params: {...?request.arguments},
    );

    return switch (response) {
      ArcaneMcpOkResponse(data: final data) => CallToolResult(
        content: [
          TextContent(text: data == null ? "" : jsonEncode(data)),
        ],
      ),
      ArcaneMcpErrorResponse(message: final message) => CallToolResult(
        content: [
          TextContent(text: message),
        ],
        isError: true,
      ),
    };
  }
}
