import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:dart_mcp/server.dart";

base class ArcaneMcpTool {
  CallToolResult textResult(String text) => CallToolResult(
    content: <Content>[TextContent(text: text)],
  );

  CallToolResult errorResult(String text) => CallToolResult(
    content: <Content>[TextContent(text: text)],
    isError: true,
  );

  CallToolResult resultFromResponse(ArcaneMcpResponse response) {
    if (response is ArcaneMcpOkResponse) {
      return textResult(
        const JsonEncoder.withIndent("  ").convert(response.data),
      );
    }
    final ArcaneMcpErrorResponse error = response as ArcaneMcpErrorResponse;
    return errorResult(error.message);
  }
}
