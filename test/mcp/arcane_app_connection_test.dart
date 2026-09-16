import "dart:async";
import "dart:convert";

import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/mcp/server/arcane_app_connection.dart";
import "package:test/test.dart";
import "package:vm_service/vm_service.dart";

import "fake_wire_server.dart";

/// A minimal VM payload advertising [isolates].
Map<String, Object?> _vm({List<Map<String, Object?>>? isolates}) =>
    <String, Object?>{
      "type": "VM",
      "name": "arcanetest",
      "version": "3.9.0",
      "isolates":
          isolates ??
          const <Map<String, Object?>>[
            <String, Object?>{"type": "@Isolate", "id": "isolates/1"},
          ],
    };

/// A minimal isolate payload exposing [extensions].
Map<String, Object?> _isolate({List<String>? extensions}) => <String, Object?>{
  "type": "Isolate",
  "id": "isolates/1",
  "number": "1",
  "name": "main",
  "isSystemIsolate": false,
  "extensionRPCs": extensions,
  "pauseEvent": <String, Object?>{"type": "Event", "kind": "None"},
};

/// A VM service handler that serves arcane-framework apps.
Future<Map<String, Object?>> Function(Map<String, Object?> request)
_arcaneHandler({
  List<String>? extensions = const <String>[arcaneMcpServiceExtension],
  List<Map<String, Object?>>? isolates,
  String? invocationsData,
}) {
  return (Map<String, Object?> request) async {
    return switch (request["method"]) {
      "getVM" => _vm(isolates: isolates),
      "getIsolate" => _isolate(extensions: extensions),
      arcaneMcpServiceExtension => <String, Object?>{
        "type": "Response",
        if (invocationsData != null) "data": invocationsData,
      },
      _ => throw StateError("unexpected request"),
    };
  };
}

/// Waits until [condition] holds, failing the test if it never does.
Future<void> _waitUntil(bool Function() condition) async {
  for (int i = 0; i < 100 && !condition(); i += 1) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  if (!condition()) fail("condition never became true");
}

void main() {
  group("ArcaneAppNotSupportedException", () {
    test("describes which app lacks the extension", () {
      final ArcaneAppNotSupportedException error =
          ArcaneAppNotSupportedException(
            "clockwork",
          );
      expect(error.appName, "clockwork");
      expect(error.toString(), contains(arcaneMcpServiceExtension));
      expect(error.toString(), contains("clockwork"));
    });
  });

  group("VmServiceArcaneAppConnection.connect", () {
    test("connects to an app exposing the extension", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(),
      );
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(
            server.uri,
            name: "clockwork",
          );
      addTearDown(connection.close);
      expect(connection.name, "clockwork");
      expect(connection.appUri, server.uri.toString());
    });

    test("falls back to host:port for an unnamed app", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(),
      );
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(server.uri);
      addTearDown(connection.close);
      expect(connection.name, "127.0.0.1:${server.uri.port}");
    });

    test("throws when the VM exposes no isolates", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(isolates: const <Map<String, Object?>>[]),
      );
      addTearDown(server.close);
      await expectLater(
        VmServiceArcaneAppConnection.connect(server.uri),
        throwsA(isA<ArcaneAppNotSupportedException>()),
      );
    });

    test("throws when the isolate lacks the extension", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(extensions: const <String>["ext.other"]),
      );
      addTearDown(server.close);
      await expectLater(
        VmServiceArcaneAppConnection.connect(server.uri),
        throwsA(isA<ArcaneAppNotSupportedException>()),
      );
    });

    test("disposes the VM service when verification fails", () async {
      final FakeWireServer server = await FakeWireServer.start(
        (Map<String, Object?> request) async {
          throw StateError("cannot reach the VM");
        },
      );
      addTearDown(server.close);
      await expectLater(
        VmServiceArcaneAppConnection.connect(server.uri),
        throwsA(isA<RPCError>()),
      );
      await _waitUntil(() => server.closedConnections >= 1);
    });
  });

  group("VmServiceArcaneAppConnection.invoke", () {
    test("calls the extension and decodes the result", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(
          invocationsData: '{"type": "result", "result": {"ok": true}}',
        ),
      );
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(
            server.uri,
            name: "clockwork",
          );
      addTearDown(connection.close);
      final ArcaneMcpResponse response = await connection.invoke(
        ArcaneMcpMethods.services,
      );
      expect(
        response,
        isA<ArcaneMcpOkResponse>().having(
          (ArcaneMcpOkResponse ok) => ok.data,
          "data",
          <String, Object?>{"ok": true},
        ),
      );
      final Map<String, Object?> extensionRequest = server.requests.last;
      expect(extensionRequest["method"], arcaneMcpServiceExtension);
      final Map<String, Object?> params = Map<String, Object?>.from(
        extensionRequest["params"] as Map,
      );
      expect(params["isolateId"], "isolates/1");
      expect(params[arcaneMcpMethodParameter], ArcaneMcpMethods.services);
      expect(jsonDecode(params[arcaneMcpParamsParameter] as String), isEmpty);
    });

    test("forwards params and decodes an error response", () async {
      final Future<Map<String, Object?>> Function(Map<String, Object?> request)
      handler;
      handler = _arcaneHandler(
        invocationsData: '{"type": "error", "error": "flag rejected"}',
      );
      final FakeWireServer server = await FakeWireServer.start(handler);
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(
            server.uri,
            name: "clockwork",
          );
      addTearDown(connection.close);
      final ArcaneMcpResponse response = await connection.invoke(
        ArcaneMcpMethods.setFeatureFlag,
        params: <String, Object?>{"name": "newHome", "enabled": true},
      );
      expect(
        response,
        isA<ArcaneMcpErrorResponse>().having(
          (ArcaneMcpErrorResponse error) => error.message,
          "message",
          "flag rejected",
        ),
      );
      final Map<String, Object?> params = Map<String, Object?>.from(
        server.requests.last["params"] as Map,
      );
      expect(
        jsonDecode(params[arcaneMcpParamsParameter] as String),
        <String, Object?>{"name": "newHome", "enabled": true},
      );
    });

    test("reports an empty response body", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(),
      );
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(
            server.uri,
            name: "clockwork",
          );
      addTearDown(connection.close);
      final ArcaneMcpResponse response = await connection.invoke(
        ArcaneMcpMethods.services,
      );
      expect(
        response,
        isA<ArcaneMcpErrorResponse>().having(
          (ArcaneMcpErrorResponse error) => error.message,
          "message",
          contains("empty response"),
        ),
      );
    });
  });

  group("VmServiceArcaneAppConnection.close", () {
    test("closes the underlying VM service", () async {
      final FakeWireServer server = await FakeWireServer.start(
        _arcaneHandler(),
      );
      addTearDown(server.close);
      final VmServiceArcaneAppConnection connection =
          await VmServiceArcaneAppConnection.connect(
            server.uri,
            name: "clockwork",
          );
      await connection.close();
      await connection.close();
      await _waitUntil(() => server.closedConnections >= 1);
    });
  });
}
