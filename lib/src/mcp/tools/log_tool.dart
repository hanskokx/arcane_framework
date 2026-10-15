import "package:arcane_framework/src/extension/arcane_log_buffer.dart";
import "package:arcane_framework/src/mcp/tools/tool.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:arcane_logger/arcane_logger.dart";
import "package:collection/collection.dart";
import "package:dart_mcp/server.dart";

class LogTool extends McpTool {
  @override
  Tool get tool => Tool(
    name: "get_logs",
    description: "Get the latest log entries.",
    inputSchema: Schema.object(
      properties: {
        "message": Schema.string(
          description: "The log message",
        ),
        "level": Schema.string(
          defaultValue: "debug",
          description: "The severity of the log message",
        ),
        "module": Schema.string(
          description: "The originator of the log message (likely a class)",
        ),
        "method": Schema.string(
          description: "The originator of the log message (likely a method)",
        ),
      },
    ),
  );

  @override
  CallToolResult handler(CallToolRequest request) {
    final String? message = request.arguments?["message"] as String?;
    final String? level = request.arguments?["level"] as String?;
    final String? module = request.arguments?["module"] as String?;
    final String? method = request.arguments?["method"] as String?;

    final ArcaneLogBuffer? loggingInterface =
        ArcaneLogger.I.interfaces.firstWhereOrNull((i) => i is ArcaneLogBuffer)
            as ArcaneLogBuffer?;

    if (null == loggingInterface) {
      throw Exception("No log buffer has been registered.");
    }

    if (loggingInterface.isEmpty) {
      throw Exception("No log entries are available");
    }

    final List<Map<String, Object?>> logs = loggingInterface.entries;

    if (null != level) {
      logs.removeWhere((log) {
        final String levelString = log["level"] as String;
        return level.toLowerCase().trim() == levelString.toLowerCase().trim();
      });
    }

    if (null != module) {
      logs.removeWhere((log) {
        final String? moduleString = log["module"] as String?;
        return module.toLowerCase().trim() ==
            moduleString?.toLowerCase().trim();
      });
    }

    if (null != method) {
      logs.removeWhere((log) {
        final String? methodString = log["method"] as String?;
        return method.toLowerCase().trim() ==
            methodString?.toLowerCase().trim();
      });
    }

    if (null != message) {
      logs.removeWhere((log) {
        final String messageString = log["message"] as String;
        return message.toLowerCase().trim() ==
            messageString.toLowerCase().trim();
      });
    }

    final List<TextContent> content = [];

    if (logs.isEmptyOrNull) {
      for (final log in logs) {
        final String message = log["message"] as String;
        final String level = log["level"] as String;
        final String? module = log["module"] as String?;
        final String? method = log["method"] as String?;
        final Map<String, Object?> metadata =
            log["metadata"] as Map<String, Object?>;

        final StringBuffer buffer = StringBuffer();

        buffer.write("[${level.capitalize}] ");
        buffer.write(message);
        buffer.write(" (module: $module) ");
        buffer.write(" (method: $method) ");
        buffer.write(metadata.toString());

        content.add(
          TextContent(
            text: buffer.toString(),
          ),
        );
      }
    }

    return CallToolResult(
      content: content,
      isError: logs.isEmpty,
    );
  }
}
