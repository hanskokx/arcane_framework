import "dart:async";
import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:arcane_framework/src/mcp/server/arcane_mcp_server.dart";
import "package:arcane_framework/src/mcp/server/dtd_discovery.dart";
import "package:dart_mcp/client.dart";
import "package:stream_channel/stream_channel.dart";
import "package:test/test.dart";

/// The tools the server registers.
const List<String> _toolNames = <String>[
  "find_apps",
  "connect_app",
  "get_services",
  "get_logs",
  "get_feature_flags",
  "set_feature_flag",
  "get_authentication",
  "get_theme",
  "set_theme_mode",
  "get_environment",
  "set_environment",
];

/// A factory that refuses to reach a live VM service; tests configure the
/// server to use scripted connections instead.
Future<ArcaneAppConnection> _refusingFactory(
  Uri uri, {
  String? name,
}) async {
  throw UnsupportedError("Unexpected live VM service connection to $uri");
}

/// A discovery that returns scripted apps without shelling out to DTD.
class _FakeDiscovery extends ArcaneAppDiscovery {
  _FakeDiscovery(this.apps);

  final List<DiscoveredApp> apps;

  /// The dtdUri passed to the last [discoverApps] call.
  String? lastDtdUri;

  @override
  Future<List<DiscoveredApp>> discoverApps({String? dtdUri}) async {
    lastDtdUri = dtdUri;
    return apps;
  }
}

/// An in-memory server/client pair wired like dart_mcp's own tests.
class _TestContext {
  _TestContext({
    List<ArcaneAppConnection> initialConnections =
        const <ArcaneAppConnection>[],
    ArcaneConnectionFactory? connectionFactory,
    ArcaneAppDiscovery? discovery,
  }) {
    _serverController = StreamController<String>();
    _clientController = StreamController<String>();
    clientChannel = StreamChannel<String>.withCloseGuarantee(
      _serverController.stream,
      _clientController.sink,
    );
    serverChannel = StreamChannel<String>.withCloseGuarantee(
      _clientController.stream,
      _serverController.sink,
    );
    client = MCPClient(
      Implementation(name: "arcane-mcp-test", version: "0.1.0"),
    );
    server = ArcaneMcpServer(
      serverChannel,
      initialConnections: initialConnections,
      connectionFactory: connectionFactory ?? _refusingFactory,
      discovery: discovery ?? _FakeDiscovery(const <DiscoveredApp>[]),
    );
    serverConnection = client.connectServer(clientChannel);
  }

  late final StreamController<String> _serverController;
  late final StreamController<String> _clientController;
  late final StreamChannel<String> clientChannel;
  late final StreamChannel<String> serverChannel;
  late final MCPClient client;
  late final ArcaneMcpServer server;
  late final ServerConnection serverConnection;
  late InitializeResult initializeResult;

  Future<void> initialize() async {
    initializeResult = await serverConnection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    expect(initializeResult.protocolVersion?.isSupported, isTrue);
    serverConnection.notifyInitialized(InitializedNotification());
    await server.initialized;
  }

  Future<void> dispose() async {
    await client.shutdown();
    await server.shutdown();
    await _serverController.close();
    await _clientController.close();
  }
}

/// Creates a context, registers its cleanup, and initializes it.
Future<_TestContext> _startedContext({
  List<ArcaneAppConnection> initialConnections = const <ArcaneAppConnection>[],
  ArcaneConnectionFactory? connectionFactory,
  ArcaneAppDiscovery? discovery,
}) async {
  final _TestContext context = _TestContext(
    initialConnections: initialConnections,
    connectionFactory: connectionFactory,
    discovery: discovery,
  );
  addTearDown(context.dispose);
  await context.initialize();
  return context;
}

/// Creates a scripted connection that records every invocation.
FakeArcaneAppConnection _recordingConnection(
  String name,
  List<String> methods,
  List<Map<String, Object?>> params,
) {
  return FakeArcaneAppConnection(name, (String method, Map<String, Object?> p) {
    methods.add(method);
    params.add(p);
    return ArcaneMcpOkResponse(<String, Object?>{
      "method": method,
      "app": name,
    });
  });
}

String _toolText(CallToolResult result) =>
    (result.content.single as TextContent).text;

void main() {
  group("initialization", () {
    test("advertises the arcane-framework server info", () async {
      final _TestContext context = await _startedContext();
      expect(context.initializeResult.serverInfo.name, "arcane-framework");
    });

    test("advertises the full tool set", () async {
      final _TestContext context = await _startedContext();
      final ListToolsResult result = await context.serverConnection.listTools();
      final List<String> names =
          result.tools.map((Tool tool) => tool.name).toList();
      expect(names, containsAll(_toolNames));
    });
  });

  group("constructor defaults", () {
    test(
      "works without explicit discovery or connection factory",
      () async {
        final StreamController<String> serverCtrl = StreamController<String>();
        final StreamController<String> clientCtrl = StreamController<String>();
        final StreamChannel<String> serverChannel =
            StreamChannel<String>.withCloseGuarantee(
              clientCtrl.stream,
              serverCtrl.sink,
            );
        final StreamChannel<String> clientChannel =
            StreamChannel<String>.withCloseGuarantee(
              serverCtrl.stream,
              clientCtrl.sink,
            );
        addTearDown(() async {
          await clientCtrl.close();
          await serverCtrl.close();
        });
        final MCPClient client = MCPClient(
          Implementation(name: "test", version: "0.1"),
        );
        final ArcaneMcpServer server = ArcaneMcpServer(serverChannel);
        final ServerConnection sc = client.connectServer(clientChannel);
        final InitializeResult ir = await sc.initialize(
          InitializeRequest(
            protocolVersion: ProtocolVersion.latestSupported,
            capabilities: client.capabilities,
            clientInfo: client.implementation,
          ),
        );
        expect(ir.protocolVersion?.isSupported, isTrue);
        sc.notifyInitialized(InitializedNotification());
        await server.initialized;
        final CallToolResult result = await sc.callTool(
          CallToolRequest(name: "get_theme"),
        );
        expect(_toolText(result), contains("No app connections"));
        await client.shutdown();
        await server.shutdown();
      },
    );
  });

  group("app targeting", () {
    test("reports when no app is connected", () async {
      final _TestContext context = await _startedContext();
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(name: "get_services"),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("No app connections"));
    });

    test("resolves the default connection", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(name: "get_services"),
      );
      expect(result.isError, isNull);
      final Object? data = jsonDecode(_toolText(result));
      expect((data as Map<String, Object?>)["app"], "clockwork");
    });

    test("targets a connection by appName", () async {
      final List<String> methods = <String>[];
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("musket", <String>[], <Map<String, Object?>>[]),
          _recordingConnection("clockwork", methods, params),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_feature_flags",
          arguments: <String, Object?>{"appName": "clockwork"},
        ),
      );
      expect(methods, <String>[ArcaneMcpMethods.featureFlags]);
      expect(result.isError, isNull);
    });

    test("rejects an ambiguous appName", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork-a",
            <String>[],
            <Map<String, Object?>>[],
          ),
          _recordingConnection(
            "clockwork-b",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_services",
          arguments: <String, Object?>{"appName": "clockwork"},
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("Multiple apps match"));
    });
  });

  group("parameter forwarding", () {
    test("set_feature_flag forwards name and enabled", () async {
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", <String>[], params),
        ],
      );
      await context.serverConnection.callTool(
        CallToolRequest(
          name: "set_feature_flag",
          arguments: <String, Object?>{
            "name": "newHomeScreen",
            "enabled": true,
          },
        ),
      );
      expect(
        params.single,
        <String, Object?>{"name": "newHomeScreen", "enabled": true},
      );
    });

    test("set_theme_mode forwards mode", () async {
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", <String>[], params),
        ],
      );
      await context.serverConnection.callTool(
        CallToolRequest(
          name: "set_theme_mode",
          arguments: <String, Object?>{"mode": "dark"},
        ),
      );
      expect(params.single, <String, Object?>{"mode": "dark"});
    });

    test("get_logs forwards its filters and drops app targeting", () async {
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", <String>[], params),
        ],
      );
      await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_logs",
          arguments: <String, Object?>{
            "level": "warning",
            "module": "example",
            "limit": 10,
          },
        ),
      );
      expect(
        params.single,
        <String, Object?>{"level": "warning", "module": "example", "limit": 10},
      );
    });

    test("connect_app opens a connection through the factory", () async {
      final FakeArcaneAppConnection scripted = _recordingConnection(
        "clockwork",
        <String>[],
        <Map<String, Object?>>[],
      );
      final _TestContext context = await _startedContext(
        connectionFactory: (Uri uri, {String? name}) async => scripted,
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"vmServiceUri": "ws://localhost:8181"},
        ),
      );
      expect(result.isError, isNull);
      expect(_toolText(result), contains("Connected to clockwork"));

      final CallToolResult services = await context.serverConnection.callTool(
        CallToolRequest(name: "get_services"),
      );
      expect(services.isError, isNull);
    });
  });

  group("resources", () {
    test("reads an app resource as indented JSON", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final ReadResourceResult result = await context.serverConnection
          .readResource(
            ReadResourceRequest(uri: "arcane://environment"),
          );
      final TextResourceContents contents =
          result.contents.single as TextResourceContents;
      expect(contents.uri, "arcane://environment");
      final Object? data = jsonDecode(contents.text);
      expect((data as Map<String, Object?>)["app"], "clockwork");
    });

    test("reports a missing connection on a resource read", () async {
      final _TestContext context = await _startedContext();
      final ReadResourceResult result = await context.serverConnection
          .readResource(
            ReadResourceRequest(uri: "arcane://theme"),
          );
      final TextResourceContents contents =
          result.contents.single as TextResourceContents;
      expect(contents.text, contains("No app connections"));
    });
  });

  group("connection bookkeeping", () {
    test("reports the connected apps", () async {
      final FakeArcaneAppConnection connection = _recordingConnection(
        "clockwork",
        <String>[],
        <Map<String, Object?>>[],
      );
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[connection],
      );
      expect(context.server.connectionCount, 1);
      expect(context.server.connections, hasLength(1));
      expect(context.server.connections.single, connection);
    });

    test("shutdown clears the connection list", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      await context.dispose();
      expect(context.server.connectionCount, 0);
    });
  });

  group("discovery", () {
    test("find_apps reports when nothing is running", () async {
      final _TestContext context = await _startedContext();
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(name: "find_apps"),
      );
      expect(result.isError, isNull);
      expect(_toolText(result), contains("No running apps discovered"));
    });

    test("find_apps forwards dtdUri and formats discovered apps", () async {
      final _FakeDiscovery discovery = _FakeDiscovery(
        const <DiscoveredApp>[
          DiscoveredApp(
            name: "clockwork",
            appUri: "ws://localhost:8181",
            dtdUri: "ws://localhost:4444/dtd",
          ),
          DiscoveredApp(
            name: "musket",
            appUri: "ws://localhost:8182",
            dtdUri: "ws://localhost:4444/dtd",
          ),
        ],
      );
      final _TestContext context = await _startedContext(discovery: discovery);
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "find_apps",
          arguments: <String, Object?>{"dtdUri": "ws://localhost:4444/dtd"},
        ),
      );
      expect(discovery.lastDtdUri, "ws://localhost:4444/dtd");
      expect(_toolText(result), contains("Discovered apps (2)"));
      expect(_toolText(result), contains("clockwork (ws://localhost:8181)"));
      expect(_toolText(result), contains("[DTD ws://localhost:4444/dtd]"));
    });

    test("connect_app targets a discovered app by name", () async {
      final List<String> methods = <String>[];
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final FakeArcaneAppConnection scripted = _recordingConnection(
        "clockwork-alpha",
        methods,
        params,
      );
      final _TestContext context = await _startedContext(
        connectionFactory: (Uri uri, {String? name}) async => scripted,
        discovery: _FakeDiscovery(
          const <DiscoveredApp>[
            DiscoveredApp(
              name: "clockwork-alpha",
              appUri: "ws://localhost:8181",
              dtdUri: "ws://localhost:4444/dtd",
            ),
          ],
        ),
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"appName": "clock"},
        ),
      );
      expect(result.isError, isNull);
      expect(_toolText(result), contains("Connected to clockwork-alpha"));
      expect(context.server.connectionCount, 1);
    });

    test("connect_app matches a discovered app by appUri", () async {
      final _FakeDiscovery discovery = _FakeDiscovery(
        const <DiscoveredApp>[
          DiscoveredApp(
            name: "clockwork",
            appUri: "ws://localhost:8181",
            dtdUri: "ws://localhost:4444/dtd",
          ),
        ],
      );
      final _TestContext context = await _startedContext(
        connectionFactory:
            (Uri uri, {String? name}) async => _recordingConnection(
              name ?? "app",
              <String>[],
              <Map<String, Object?>>[],
            ),
        discovery: discovery,
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"appUri": "ws://localhost:8181"},
        ),
      );
      expect(result.isError, isNull);
      expect(_toolText(result), contains("Connected to clockwork"));
    });

    test("connect_app reports when no app matches", () async {
      final _TestContext context = await _startedContext(
        discovery: _FakeDiscovery(
          const <DiscoveredApp>[
            DiscoveredApp(
              name: "clockwork",
              appUri: "ws://localhost:8181",
              dtdUri: "ws://localhost:4444/dtd",
            ),
          ],
        ),
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{
            "appName": "nope",
            "appUri": "ws://localhost:9999",
          },
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("No running app matched"));
    });

    test("connect_app rejects an ambiguous match", () async {
      final _TestContext context = await _startedContext(
        discovery: _FakeDiscovery(
          const <DiscoveredApp>[
            DiscoveredApp(
              name: "clockwork-a",
              appUri: "ws://localhost:8181",
              dtdUri: "ws://localhost:4444/dtd",
            ),
            DiscoveredApp(
              name: "clockwork-b",
              appUri: "ws://localhost:8182",
              dtdUri: "ws://localhost:4444/dtd",
            ),
          ],
        ),
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"appName": "clockwork"},
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("Multiple apps match"));
    });
  });

  group("connection errors", () {
    test("reports an unsupported app", () async {
      final _TestContext context = await _startedContext(
        connectionFactory: (Uri uri, {String? name}) async {
          throw ArcaneAppNotSupportedException("plainapp");
        },
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"vmServiceUri": "ws://localhost:8181"},
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("does not expose"));
    });

    test("reports a failed connection", () async {
      final _TestContext context = await _startedContext(
        connectionFactory: (Uri uri, {String? name}) async {
          throw Exception("refused");
        },
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "connect_app",
          arguments: <String, Object?>{"vmServiceUri": "ws://localhost:8181"},
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("Failed to connect to"));
      expect(_toolText(result), contains("refused"));
    });
  });

  group("remaining tools", () {
    test("get_authentication forwards includeTokens", () async {
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", <String>[], params),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_authentication",
          arguments: <String, Object?>{"includeTokens": true},
        ),
      );
      expect(result.isError, isNull);
      expect(
        params.single,
        <String, Object?>{"includeTokens": true},
      );
    });

    test("get_theme invokes the theme method", () async {
      final List<String> methods = <String>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", methods, <Map<String, Object?>>[]),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(name: "get_theme"),
      );
      expect(result.isError, isNull);
      expect(methods, <String>[ArcaneMcpMethods.theme]);
    });

    test("get_environment and set_environment invoke their methods", () async {
      final List<String> methods = <String>[];
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", methods, params),
        ],
      );
      await context.serverConnection.callTool(
        CallToolRequest(name: "get_environment"),
      );
      await context.serverConnection.callTool(
        CallToolRequest(
          name: "set_environment",
          arguments: <String, Object?>{"name": "production"},
        ),
      );
      expect(
        methods,
        <String>[ArcaneMcpMethods.environment, ArcaneMcpMethods.setEnvironment],
      );
      expect(params.last, <String, Object?>{"name": "production"});
    });

    test("get_logs reports when no app is connected", () async {
      final _TestContext context = await _startedContext();
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(name: "get_logs"),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("No app connections"));
    });

    test("get_logs forwards the search filter", () async {
      final List<Map<String, Object?>> params = <Map<String, Object?>>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection("clockwork", <String>[], params),
        ],
      );
      await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_logs",
          arguments: <String, Object?>{"search": "startup"},
        ),
      );
      expect(params.single, <String, Object?>{"search": "startup"});
    });

    test("a tool surfaces a bridge error response", () async {
      final FakeArcaneAppConnection connection = FakeArcaneAppConnection(
        "clockwork",
        (String method, Map<String, Object?> params) =>
            const ArcaneMcpErrorResponse("league services down"),
      );
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[connection],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "set_feature_flag",
          arguments: <String, Object?>{"name": "newHome", "enabled": true},
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), "league services down");
    });
  });

  group("app targeting details", () {
    test("targets a connection by appUri", () async {
      final List<String> methods = <String>[];
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork-a",
            methods,
            <Map<String, Object?>>[],
          ),
          _recordingConnection(
            "clockwork-b",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_services",
          arguments: <String, Object?>{"appUri": "fake://clockwork-a"},
        ),
      );
      expect(result.isError, isNull);
      expect(methods, <String>[ArcaneMcpMethods.services]);
    });

    test("reports when no connection matches name and uri", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final CallToolResult result = await context.serverConnection.callTool(
        CallToolRequest(
          name: "get_services",
          arguments: <String, Object?>{
            "appName": "ghost",
            "appUri": "fake://ghost",
          },
        ),
      );
      expect(result.isError, isTrue);
      expect(_toolText(result), contains("No connection matches"));
      expect(_toolText(result), contains("appName=ghost"));
    });
  });

  group("resource errors", () {
    test("reports an unknown resource URI", () async {
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[
          _recordingConnection(
            "clockwork",
            <String>[],
            <Map<String, Object?>>[],
          ),
        ],
      );
      final ReadResourceResult result = await context.serverConnection
          .readResource(ReadResourceRequest(uri: "arcane://bogus"));
      final TextResourceContents contents =
          result.contents.single as TextResourceContents;
      expect(contents.uri, "arcane://bogus");
      expect(contents.text, contains("Unknown resource URI"));
    });

    test("surfaces a bridge error in a resource read", () async {
      final FakeArcaneAppConnection connection = FakeArcaneAppConnection(
        "clockwork",
        (String method, Map<String, Object?> params) =>
            const ArcaneMcpErrorResponse("no theme configured"),
      );
      final _TestContext context = await _startedContext(
        initialConnections: <ArcaneAppConnection>[connection],
      );
      final ReadResourceResult result = await context.serverConnection
          .readResource(ReadResourceRequest(uri: "arcane://theme"));
      final TextResourceContents contents =
          result.contents.single as TextResourceContents;
      expect(contents.text, "Error: no theme configured");
    });
  });

  group("lifecycle", () {
    test("shutdown closes connected apps", () async {
      final FakeArcaneAppConnection scripted = _recordingConnection(
        "clockwork",
        <String>[],
        <Map<String, Object?>>[],
      );
      final _TestContext context = _TestContext(
        initialConnections: <ArcaneAppConnection>[scripted],
      );
      await context.initialize();
      await context.dispose();
      expect(scripted.isClosed, isTrue);
    });
  });
}
