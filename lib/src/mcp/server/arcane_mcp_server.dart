import "dart:convert";

import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/tools/arcane_version_tool.dart";
import "package:arcane_framework/src/mcp/tools/connect_tool.dart";
import "package:arcane_framework/src/mcp/tools/log_tool.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:collection/collection.dart";
import "package:dart_mcp/server.dart";
import "package:shelf/shelf.dart" as shelf;
import "package:shelf/shelf_io.dart" as shelf_io;

import "../tools/tool.dart";

base class ArcaneMcpServer extends MCPServer with ToolsSupport {
  static List<McpTool> tools = [
    LogTool(),
    ArcaneVersionTool(),
    ConnectTool(),
  ];

  ArcaneAppConnection? _connection;

  ArcaneMcpServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: "arcane-mcp-server",
          version: ArcaneVersionTool.arcaneFrameworkVersion,
        ),
        instructions:
            "Communicate with the current Arcane application using ${[
              tools.map((e) => e.tool.name).toList(),
            ].join(" ")}",
      ) {
    for (final tool in tools) {
      try {
        registerTool(
          tool.tool,
          (request) => tool.handler(request, _connection, this),
        );
      } catch (e) {
        print("Failed to register tool ${tool.tool.name}:\n$e");
      }
    }
  }

  Future<void> connect(ArcaneAppConnection connection) async {
    await _connection?.close();
    _connection = connection;
  }

  Future<void> serveHttp() async {
    Future<shelf.Response> handler(shelf.Request request) async {
      if (request.method != "POST") {
        return shelf.Response(405);
      }
      final String body = await request.readAsString();

      final jsonReq = jsonDecode(body) as Map<String, dynamic>?;
      if (jsonReq == null) {
        return shelf.Response(400);
      }
      final String method = jsonReq["method"] as String;
      final Object? id = jsonReq["id"];

      // A JSON-RPC request with no id is a
      // notification: the spec says send no reply.
      if (id == null) {
        return shelf.Response(202);
      }

      final params = jsonReq["params"] as Map<String, dynamic>? ?? {};
      Map<String, dynamic> result;
      switch (method) {
        case "initialize":
          result = {
            // TODO(hans): Figure out what this should be
            "protocolVersion": "2025-06-18",
            "capabilities": {"tools": {}},
            "serverInfo": {
              "name": "arcane-mcp-server",
              "version": ArcaneVersionTool.arcaneFrameworkVersion,
            },
          };
        case "tools/list":
          result = {
            "tools": [
              ...ArcaneMcpServer.tools
                  .map(
                    (e) => {
                      "name": e.tool.name,
                      "description": e.tool.description,
                      "inputSchema": e.tool.inputSchema.toJsonValue(),
                    },
                  )
                  .toList(),
            ],
          };
        case "tools/call":
          final tool = ArcaneMcpServer.tools.firstWhereOrNull(
            (e) => e.tool.name == (params["name"] as String),
          );
          if (tool != null) {
            final resultObj = await tool.handler(
              CallToolRequest(
                name: params["name"] as String,
                arguments: params,
              ),
              _connection,
              this,
            );
            result = Map<String, dynamic>.from(
              resultObj.structuredContent ?? {},
            );
          } else {
            result = {};
          }
        default:
          result = {};
      }
      return shelf.Response.ok(
        jsonEncode({
          "jsonrpc": "2.0",
          "id": id,
          "result": result,
        }),
        headers: {
          "content-type": "application/json",
        },
      );
    }

    final server = await shelf_io.serve(
      handler,
      "localhost",
      8087,
    );
    print(
      "MCP server running on "
      "http://${server.address.host}:"
      "${server.port}",
    );
  }
}
