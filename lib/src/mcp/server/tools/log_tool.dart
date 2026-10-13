import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_tool.dart";
import "package:dart_mcp/server.dart";

final class LogTool extends ArcaneMcpTool {
  Future<CallToolResult> handleGetLogs(
    CallToolRequest request,
    ArcaneAppConnection connection,
  ) async {
    final Map<String, Object?> args =
        request.arguments ?? const <String, Object?>{};

    final Map<String, Object?> params = <String, Object?>{
      if (args.containsKey(ArcaneMcpParams.level))
        ArcaneMcpParams.level: args[ArcaneMcpParams.level],
      if (args.containsKey(ArcaneMcpParams.module))
        ArcaneMcpParams.module: args[ArcaneMcpParams.module],
      if (args.containsKey(ArcaneMcpParams.search))
        ArcaneMcpParams.search: args[ArcaneMcpParams.search],
      if (args.containsKey(ArcaneMcpParams.limit))
        ArcaneMcpParams.limit: args[ArcaneMcpParams.limit],
    };
    final ArcaneMcpResponse response = await connection.invoke(
      ArcaneMcpMethods.logs,
      params: params,
    );
    return resultFromResponse(response);
  }
}
