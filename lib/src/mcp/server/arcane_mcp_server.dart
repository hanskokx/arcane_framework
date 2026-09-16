import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:dart_mcp/server.dart";
import "package:stream_channel/stream_channel.dart";

import "arcane_app_connection.dart";
import "dtd_discovery.dart";

const String _serverInstructions =
    "Connect to a running arcane_framework app with 'connect_app' (or by "
    "passing vmServiceUri directly), then read state with the get_* tools and "
    "the arcane://* resources. Use appName to target a specific app when "
    "several are connected. Apps based on ArcaneApp expose the extension "
    "automatically.";

/// A factory that opens an [ArcaneAppConnection] to a VM service URI.
///
/// Tests inject their own factory to script connections without a live app.
typedef ArcaneConnectionFactory =
    Future<ArcaneAppConnection> Function(
      Uri uri, {
      String? name,
    });

/// An MCP server exposing running arcane_framework apps.
///
/// Communicates over the [StreamChannel<String>] passed to the constructor
/// (normally stdio created by `stdioChannel`, see `bin/arcane_mcp_server.dart`).
/// The server discovers running apps with [ArcaneAppDiscovery], connects to a
/// chosen app's VM service, and mirrors the app's bridge methods as MCP tools
/// (`find_apps`, `connect_app`, `get_services`, `get_logs`,
/// `get_feature_flags`, `set_feature_flag`, `get_authentication`, `get_theme`,
/// `set_theme_mode`, `get_environment`, `set_environment`) and as
/// `arcane://*` resources.
base class ArcaneMcpServer extends MCPServer
    with LoggingSupport, ToolsSupport, ResourcesSupport {
  /// Creates the server on [channel].
  ///
  /// [discovery] discovers running apps (defaults to [ArcaneAppDiscovery]).
  /// [connectionFactory] opens a connection for a VM service URI (defaults to
  /// [VmServiceArcaneAppConnection.connect]). [initialConnections] attaches
  /// pre-established connections (used by tests).
  ArcaneMcpServer(
    StreamChannel<String> channel, {
    ArcaneAppDiscovery? discovery,
    ArcaneConnectionFactory? connectionFactory,
    List<ArcaneAppConnection> initialConnections =
        const <ArcaneAppConnection>[],
  }) : _discovery = discovery ?? ArcaneAppDiscovery(),
       _connectionFactory =
           connectionFactory ?? VmServiceArcaneAppConnection.connect,
       super.fromStreamChannel(
         channel,
         implementation: Implementation(
           name: "arcane-framework",
           version: "3.0.0-dev.1",
           description: "Working with arcane_framework apps.",
         ),
         instructions: _serverInstructions,
       ) {
    _connections.addAll(initialConnections);
    _registerTools();
    _registerResources();
  }

  final ArcaneAppDiscovery _discovery;
  final ArcaneConnectionFactory _connectionFactory;
  final List<ArcaneAppConnection> _connections = <ArcaneAppConnection>[];

  /// The number of currently connected apps.
  int get connectionCount => _connections.length;

  /// The apps this server is currently connected to.
  List<ArcaneAppConnection> get connections =>
      List<ArcaneAppConnection>.unmodifiable(_connections);

  // -- Tools -------------------------------------------------------------- //

  void _registerTools() {
    registerTool(
      Tool(
        name: "find_apps",
        description:
            "Discovers running Flutter apps through the Dart Tooling Daemon. "
            "Returns each app's name and VM service URI. Pass dtdUri to "
            "restrict discovery to one daemon.",
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.dtdUri: StringSchema(),
          },
          required: const <String>[],
        ),
      ),
      _handleFindApps,
    );
    registerTool(
      Tool(
        name: "connect_app",
        description:
            "Connects to a running app. Pass either vmServiceUri for a direct "
            "connection, or appName and/or appUri discovered with find_apps. "
            "The app must be running and mount ArcaneApp so it exposes "
            "ext.arcane.devtools.invoke.",
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.appName: StringSchema(),
            ArcaneMcpParams.appUri: StringSchema(),
            ArcaneMcpParams.dtdUri: StringSchema(),
            ArcaneMcpParams.vmServiceUri: StringSchema(),
          },
          required: const <String>[],
        ),
      ),
      _handleConnectApp,
    );
    registerTool(
      _annotatedTool(
        name: "get_services",
        description:
            "Lists the services registered on the connected app with a "
            "per-type summary (feature flags, authentication, theme, "
            "environment).",
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.services, request),
    );
    registerTool(
      _annotatedTool(
        name: "get_logs",
        description:
            "Returns the log events buffered by the app. Filters: level "
            "(all, trace, debug, info, warning, error, fatal, off), module, "
            "search, limit.",
      ),
      _handleGetLogs,
    );
    registerTool(
      _annotatedTool(
        name: "get_feature_flags",
        description:
            "Returns the app's enabled feature flags and the set of "
            "known feature flags.",
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.featureFlags, request),
    );
    registerTool(
      Tool(
        name: "set_feature_flag",
        description:
            "Enables or disables a feature flag on the app by name. The flag "
            "must be known to the app: the app has to enable or disable it in "
            "code with Arcane.features.enableFeature/disableFeature at least "
            "once.",
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.name: StringSchema(),
            ArcaneMcpParams.enabled: BooleanSchema(),
            ArcaneMcpParams.appName: StringSchema(),
            ArcaneMcpParams.appUri: StringSchema(),
          },
          required: const <String>[
            ArcaneMcpParams.name,
            ArcaneMcpParams.enabled,
          ],
        ),
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.setFeatureFlag, request),
    );
    registerTool(
      _annotatedTool(
        name: "get_authentication",
        description:
            "Returns the app's authentication state. Pass includeTokens=true "
            "to also reveal the access and refresh tokens; do not request "
            "tokens unless required.",
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.authentication, request),
    );
    registerTool(
      _annotatedTool(
        name: "get_theme",
        description:
            "Returns the app's theme mode, active brightness, and the theme "
            "primary colors.",
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.theme, request),
    );
    registerTool(
      Tool(
        name: "set_theme_mode",
        description: "Sets the app's theme mode to light, dark, or system.",
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.mode: UntitledSingleSelectEnumSchema(
              values: <String>["light", "dark", "system"],
            ),
            ArcaneMcpParams.appName: StringSchema(),
            ArcaneMcpParams.appUri: StringSchema(),
          },
          required: const <String>[ArcaneMcpParams.mode],
        ),
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.setThemeMode, request),
    );
    registerTool(
      _annotatedTool(
        name: "get_environment",
        description: "Returns the app's current application environment.",
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.environment, request),
    );
    registerTool(
      Tool(
        name: "set_environment",
        description:
            "Sets the app's application environment by name (for example "
            "'debug', 'normal', or a custom environment name).",
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.name: StringSchema(),
            ArcaneMcpParams.appName: StringSchema(),
            ArcaneMcpParams.appUri: StringSchema(),
          },
          required: const <String>[ArcaneMcpParams.name],
        ),
      ),
      (CallToolRequest request) =>
          _invokeAndFormat(ArcaneMcpMethods.setEnvironment, request),
    );
  }

  Tool _annotatedTool({required String name, required String description}) =>
      Tool(
        name: name,
        description: description,
        inputSchema: ObjectSchema(
          properties: <String, Schema>{
            ArcaneMcpParams.appName: StringSchema(),
            ArcaneMcpParams.appUri: StringSchema(),
          },
          required: const <String>[],
        ),
      );

  Future<CallToolResult> _handleFindApps(CallToolRequest request) async {
    final String? dtdUri =
        (request.arguments ?? const <String, Object?>{})[ArcaneMcpParams.dtdUri]
            ?.toString();
    final List<DiscoveredApp> apps = await _discovery.discoverApps(
      dtdUri: dtdUri,
    );
    return _textResult(_formatDiscoveredApps(apps));
  }

  Future<CallToolResult> _handleConnectApp(CallToolRequest request) async {
    final Map<String, Object?> args =
        request.arguments ?? const <String, Object?>{};
    final String? appName = args[ArcaneMcpParams.appName]?.toString();
    final String? appUri = args[ArcaneMcpParams.appUri]?.toString();
    final String? dtdUri = args[ArcaneMcpParams.dtdUri]?.toString();
    final String? vmServiceUri = args[ArcaneMcpParams.vmServiceUri]?.toString();

    if (vmServiceUri != null) {
      return _connectToUri(Uri.parse(vmServiceUri), name: appName);
    }

    final List<DiscoveredApp> apps = await _discovery.discoverApps(
      dtdUri: dtdUri,
    );
    final List<DiscoveredApp> matches = <DiscoveredApp>[];
    for (final DiscoveredApp app in apps) {
      final bool nameMatches =
          appName == null ||
          app.name.toLowerCase().contains(appName.toLowerCase());
      final bool uriMatches = appUri == null || app.appUri == appUri;
      if (nameMatches && uriMatches) {
        matches.add(app);
      }
    }
    if (matches.isEmpty) {
      return _errorResult(
        "No running app matched $appName$appUri. "
        "${_formatDiscoveredApps(apps)}",
      );
    }
    if (matches.length > 1) {
      return _errorResult(
        "Multiple apps match. Disambiguate with appName or appUri:\n"
        "${_formatDiscoveredApps(matches)}",
      );
    }
    return _connectToUri(
      Uri.parse(matches.single.appUri),
      name: matches.single.name,
    );
  }

  Future<CallToolResult> _connectToUri(Uri uri, {String? name}) async {
    try {
      final ArcaneAppConnection connection = await _connectionFactory(
        uri,
        name: name,
      );
      _connections.add(connection);
      log(
        LoggingLevel.info,
        "Connected to ${connection.name} (${connection.appUri}).",
      );
      return _textResult(
        "Connected to ${connection.name} (${connection.appUri}).\n\n"
        "${_formatConnections()}",
      );
    } on ArcaneAppNotSupportedException catch (error) {
      return _errorResult(error.toString());
    } catch (error) {
      return _errorResult("Failed to connect to $uri: $error");
    }
  }

  Future<CallToolResult> _handleGetLogs(CallToolRequest request) async {
    final Map<String, Object?> args =
        request.arguments ?? const <String, Object?>{};
    final (ArcaneAppConnection?, String?) resolved = _resolveConnection(args);
    final ArcaneAppConnection? connection = resolved.$1;
    if (connection == null) return _errorResult(resolved.$2!);
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
    return _resultFromResponse(response);
  }

  Future<CallToolResult> _invokeAndFormat(
    String method,
    CallToolRequest request,
  ) async {
    final Map<String, Object?> args =
        request.arguments ?? const <String, Object?>{};
    final (ArcaneAppConnection?, String?) resolved = _resolveConnection(args);
    final ArcaneAppConnection? connection = resolved.$1;
    if (connection == null) return _errorResult(resolved.$2!);
    final ArcaneMcpResponse response = await connection.invoke(
      method,
      params: _bridgeParams(args),
    );
    return _resultFromResponse(response);
  }

  // -- Resources ---------------------------------------------------------- //

  void _registerResources() {
    _addResource(
      "overview",
      "Arcane overview",
      "App and service summary plus logger state.",
    );
    _addResource(
      "services",
      "Registered services",
      "The list of registered Arcane services with a per-type summary.",
    );
    _addResource(
      "logs",
      "Recent logs",
      "The log events buffered by the app's Arcane logger.",
    );
    _addResource(
      "feature_flags",
      "Feature flags",
      "The enabled feature flags and the set of known feature flags.",
    );
    _addResource(
      "authentication",
      "Authentication",
      "The current authentication state.",
    );
    _addResource(
      "theme",
      "Theme",
      "The current theme mode, brightness, and theme colors.",
    );
    _addResource(
      "environment",
      "Environment",
      "The current application environment.",
    );
    addResourceTemplate(
      ResourceTemplate(
        uriTemplate: "arcane://{resource}",
        name: "Arcane resource",
        description:
            "Any resource under the arcane:// scheme, including registered "
            "resources rendered with the app's latest state.",
        mimeType: "application/json",
      ),
      (ReadResourceRequest request) => _handleReadResource(request.uri),
    );
  }

  void _addResource(String slug, String name, String description) {
    final String uri = "arcane://$slug";
    addResource(
      Resource(
        uri: uri,
        name: name,
        description: description,
        mimeType: "application/json",
      ),
      (ReadResourceRequest request) => _handleReadResource(uri),
    );
  }

  Future<ReadResourceResult> _handleReadResource(String uri) async {
    final String? method = switch (uri) {
      "arcane://overview" => ArcaneMcpMethods.overview,
      "arcane://services" => ArcaneMcpMethods.services,
      "arcane://logs" => ArcaneMcpMethods.logs,
      "arcane://feature_flags" => ArcaneMcpMethods.featureFlags,
      "arcane://authentication" => ArcaneMcpMethods.authentication,
      "arcane://theme" => ArcaneMcpMethods.theme,
      "arcane://environment" => ArcaneMcpMethods.environment,
      _ => null,
    };
    if (method == null) {
      return _resourceResult(uri, text: "Unknown resource URI: $uri");
    }
    final (ArcaneAppConnection?, String?) resolved = _resolveConnection(
      const <String, Object?>{},
    );
    final ArcaneAppConnection? connection = resolved.$1;
    if (connection == null) {
      return _resourceResult(
        uri,
        text: resolved.$2 ?? "No app connections.",
      );
    }
    final ArcaneMcpResponse response = await connection.invoke(method);
    if (response is ArcaneMcpOkResponse) {
      return _resourceResult(
        uri,
        text: const JsonEncoder.withIndent("  ").convert(response.data),
      );
    }
    final ArcaneMcpErrorResponse error = response as ArcaneMcpErrorResponse;
    return _resourceResult(uri, text: "Error: ${error.message}");
  }

  ReadResourceResult _resourceResult(String uri, {required String text}) =>
      ReadResourceResult(
        contents: <ResourceContents>[
          TextResourceContents(uri: uri, text: text),
        ],
      );

  // -- Connection resolution ---------------------------------------------- //

  /// Resolves the app targeted by [args] among the connected apps.
  ///
  /// Returns the connection on success, or `null` plus a human-readable
  /// explanation when none (or an ambiguous set) matches.
  (ArcaneAppConnection?, String?) _resolveConnection(
    Map<String, Object?> args,
  ) {
    final String? appName = args[ArcaneMcpParams.appName]?.toString();
    final String? appUri = args[ArcaneMcpParams.appUri]?.toString();
    if (_connections.isEmpty) {
      return (null, "No app connections. Run connect_app first.");
    }
    Iterable<ArcaneAppConnection> candidates = _connections;
    if (appName != null) {
      candidates = candidates.where(
        (ArcaneAppConnection c) =>
            c.name.toLowerCase().contains(appName.toLowerCase()),
      );
    }
    if (appUri != null) {
      candidates = candidates.where(
        (ArcaneAppConnection c) => c.appUri == appUri,
      );
    }
    final List<ArcaneAppConnection> matches = candidates.toList();
    if (matches.isEmpty) {
      return (
        null,
        "No connection matches appName=$appName appUri=$appUri.\n\n"
            "${_formatConnections()}",
      );
    }
    if (matches.length > 1) {
      return (
        null,
        "Multiple apps match appName=$appName appUri=$appUri; pass a unique "
            "appName.\n\n${_formatConnections()}",
      );
    }
    return (matches.single, null);
  }

  Map<String, Object?> _bridgeParams(Map<String, Object?> args) {
    final Map<String, Object?> params = <String, Object?>{};
    for (final String key in <String>[
      ArcaneMcpParams.name,
      ArcaneMcpParams.enabled,
      ArcaneMcpParams.mode,
      ArcaneMcpParams.includeTokens,
    ]) {
      final Object? value = args[key];
      if (value != null) params[key] = value;
    }
    return params;
  }

  // -- Formatting --------------------------------------------------------- //

  String _formatConnections() {
    if (_connections.isEmpty) {
      return "No app connections. Run connect_app first.";
    }
    return "Connected apps (${_connections.length}):\n"
        '${_connections.map((ArcaneAppConnection c) => '  - ${c.name} (${c.appUri})').join('\n')}';
  }

  String _formatDiscoveredApps(List<DiscoveredApp> apps) {
    if (apps.isEmpty) {
      return "No running apps discovered. Start a Flutter app based on "
          "ArcaneApp, then run connect_app.";
    }
    return "Discovered apps (${apps.length}):\n"
        '${apps.map((DiscoveredApp app) => '  - ${app.name} (${app.appUri}) [DTD ${app.dtdUri}]').join('\n')}';
  }

  CallToolResult _textResult(String text) => CallToolResult(
    content: <Content>[TextContent(text: text)],
  );

  CallToolResult _errorResult(String text) => CallToolResult(
    content: <Content>[TextContent(text: text)],
    isError: true,
  );

  CallToolResult _resultFromResponse(ArcaneMcpResponse response) {
    if (response is ArcaneMcpOkResponse) {
      return _textResult(
        const JsonEncoder.withIndent("  ").convert(response.data),
      );
    }
    final ArcaneMcpErrorResponse error = response as ArcaneMcpErrorResponse;
    return _errorResult(error.message);
  }

  @override
  Future<void> shutdown() async {
    await Future.wait(<Future<void>>[
      for (final ArcaneAppConnection connection in _connections)
        connection.close(),
    ]);
    _connections.clear();
    await super.shutdown();
  }
}
