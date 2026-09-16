import "dart:async";
import "dart:convert";
import "dart:io";

/// A local WebSocket endpoint that answers JSON-RPC requests, standing in for
/// the Dart Tooling Daemon, a VM service, or any other wire service the MCP
/// server talks to.
///
/// Tests use this instead of running a real DTD or Flutter app so the
/// discovery and connection layers can be scripted deterministically.
class FakeWireServer {
  FakeWireServer._(
    this._server,
    this.uri,
  );

  final HttpServer _server;
  final List<WebSocket> _sockets = <WebSocket>[];

  /// The `ws://` URI clients connect to.
  final Uri uri;

  /// The raw JSON-RPC requests received, in arrival order.
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  int _closedConnections = 0;

  /// How many client connections have terminated.
  int get closedConnections => _closedConnections;

  /// Starts a server that answers every request with [handler]'s result.
  ///
  /// [handler] receives the decoded JSON-RPC request and returns the `result`
  /// payload. It may throw to produce a JSON-RPC error response.
  static Future<FakeWireServer> start(
    Future<Map<String, Object?>> Function(Map<String, Object?> request) handler,
  ) async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FakeWireServer fake = FakeWireServer._(
      server,
      Uri.parse("ws://127.0.0.1:${server.port}"),
    );
    server.listen((HttpRequest request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      final WebSocket socket;
      try {
        socket = await WebSocketTransformer.upgrade(request);
      } catch (_) {
        return;
      }
      fake._sockets.add(socket);
      socket.listen((Object? data) async {
        final Object? decoded;
        try {
          decoded = jsonDecode(data as String);
        } on FormatException {
          return;
        }
        if (decoded is! Map<String, Object?>) return;
        fake.requests.add(decoded);
        final Object? id = decoded["id"];
        if (id == null) return;
        final Map<String, Object?> response = await _buildResponse(
          handler,
          decoded,
          id,
        );
        try {
          socket.add(jsonEncode(response));
        } catch (_) {
          // The client went away before the response was sent.
        }
      });
      unawaited(
        socket.done.whenComplete(() {
          fake._sockets.remove(socket);
          fake._closedConnections += 1;
        }),
      );
    });
    return fake;
  }

  static Future<Map<String, Object?>> _buildResponse(
    Future<Map<String, Object?>> Function(Map<String, Object?> request) handler,
    Map<String, Object?> request,
    Object? id,
  ) async {
    try {
      return <String, Object?>{
        "jsonrpc": "2.0",
        "id": id,
        "result": await handler(request),
      };
    } catch (error) {
      return <String, Object?>{
        "jsonrpc": "2.0",
        "id": id,
        "error": <String, Object?>{"code": -32000, "message": "$error"},
      };
    }
  }

  /// Closes every open client connection and shuts the server down.
  Future<void> close() async {
    for (final WebSocket socket in List<WebSocket>.of(_sockets)) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}
