import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:meta/meta.dart";
import "package:vm_service/vm_service.dart";
import "package:vm_service/vm_service_io.dart";

/// Thrown when a VM service does not expose the
/// [arcaneMcpServiceExtension] extension.
class ArcaneAppNotSupportedException implements Exception {
  ArcaneAppNotSupportedException(this.appName);

  /// The name (or URI) of the app that lacks the extension.
  final String appName;

  @override
  String toString() =>
      'The app "$appName" does not expose $arcaneMcpServiceExtension. Apps '
      "based on ArcaneApp expose the extension automatically when running a "
      "debug build; make sure the app is in debug mode and mounts ArcaneApp.";
}

/// A connection to a running arcane_framework app that can answer MCP
/// invocations.
abstract interface class ArcaneAppConnection {
  /// The human-readable name of the app.
  String get name;

  /// The URI resolved for this connection (a VM service URI or a fake URI in
  /// tests).
  String get appUri;

  /// Invokes [method] with [params] on the app's bridge and decodes the
  /// response.
  Future<ArcaneMcpResponse> invoke(
    String method, {
    Map<String, Object?> params = const <String, Object?>{},
  });

  /// Closes the underlying connection to the app.
  Future<void> close();
}

/// A connection to an app over its VM service.
class VmServiceArcaneAppConnection implements ArcaneAppConnection {
  VmServiceArcaneAppConnection._({
    required this.name,
    required this.appUri,
    required VmService vmService,
    required String isolateId,
  }) : _vmService = vmService,
       _isolateId = isolateId;

  /// Connects to the app exposing its VM service at [uri].
  ///
  /// Verifies that the app's main isolate exposes the
  /// [arcaneMcpServiceExtension] extension and throws
  /// [ArcaneAppNotSupportedException] if it does not.
  static Future<VmServiceArcaneAppConnection> connect(
    Uri uri, {
    String? name,
  }) async {
    final VmService vmService = await vmServiceConnectUri(uri.toString());
    try {
      final VM vm = await vmService.getVM();
      final List<IsolateRef> isolates = vm.isolates ?? const <IsolateRef>[];
      if (isolates.isEmpty) {
        throw ArcaneAppNotSupportedException(name ?? uri.toString());
      }
      final String isolateId = isolates.first.id!;
      final Isolate isolate = await vmService.getIsolate(isolateId);
      final List<String> extensions = isolate.extensionRPCs ?? const <String>[];
      if (!extensions.contains(arcaneMcpServiceExtension)) {
        throw ArcaneAppNotSupportedException(name ?? uri.toString());
      }
      return VmServiceArcaneAppConnection._(
        name: name ?? "${uri.host}:${uri.port}",
        appUri: uri.toString(),
        vmService: vmService,
        isolateId: isolateId,
      );
    } catch (_) {
      await vmService.dispose();
      rethrow;
    }
  }

  @override
  final String name;

  @override
  final String appUri;

  final VmService _vmService;
  final String _isolateId;

  @override
  Future<ArcaneMcpResponse> invoke(
    String method, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    final Response response = await _vmService.callServiceExtension(
      arcaneMcpServiceExtension,
      isolateId: _isolateId,
      args: <String, String>{
        arcaneMcpMethodParameter: method,
        arcaneMcpParamsParameter: jsonEncode(params),
      },
    );
    final String? data = response.json?["data"] as String?;
    if (data == null) {
      return const ArcaneMcpErrorResponse(
        "The app returned an empty response for the invocation.",
      );
    }
    return arcaneMcpDecode(data);
  }

  @override
  Future<void> close() async {
    try {
      await _vmService.dispose();
    } catch (_) {
      // The app may already be gone; nothing to clean up.
    }
  }
}

/// A scripted app connection used by the server tests.
@visibleForTesting
class FakeArcaneAppConnection implements ArcaneAppConnection {
  FakeArcaneAppConnection(this.name, this.handler);

  @override
  final String name;

  /// Maps a method invocation to its response.
  final ArcaneMcpResponse Function(String method, Map<String, Object?> params)
  handler;

  bool _closed = false;

  /// Whether [close] has been called.
  bool get isClosed => _closed;

  @override
  String get appUri => "fake://$name";

  @override
  Future<ArcaneMcpResponse> invoke(
    String method, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    return handler(method, params);
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}
