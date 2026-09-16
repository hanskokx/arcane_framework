import "dart:io";

import "package:arcane_framework/src/mcp/server/dtd_discovery.dart";
import "package:test/test.dart";

import "fake_wire_server.dart";

/// Writes an executable script that prints [body] verbatim, standing in for
/// the `dart tooling-daemon --list --machine` command.
Future<File> _printFixture(String body) async {
  final Directory dir = await Directory.systemTemp.createTemp("dtd_fixture_");
  addTearDown(() => dir.delete(recursive: true));
  final File script = File("${dir.path}/fake_dtd_list");
  await script.writeAsString("#!/usr/bin/env sh\ncat <<'EOF'\n$body\nEOF\n");
  await Process.run("chmod", <String>["+x", script.path]);
  return script;
}

/// Writes an executable script that fails the `tooling-daemon` invocation.
Future<File> _failingFixture() async {
  final Directory dir = await Directory.systemTemp.createTemp("dtd_fixture_");
  addTearDown(() => dir.delete(recursive: true));
  final File script = File("${dir.path}/fake_dtd_list");
  await script.writeAsString(
    "#!/usr/bin/env sh\nprintf '%s' 'boom' >&2\nexit 3\n",
  );
  await Process.run("chmod", <String>["+x", script.path]);
  return script;
}

/// A DTD list entry advertising a single instance at [wsUri].
String _instance(String wsUri) =>
    '{"wsUri": "$wsUri", "dartVersion": "3.9.0", '
    '"workspaceRoot": "/tmp/ws", "pid": 4242, "ideName": "VsCode"}';

/// A full DTD list payload advertising a single instance at [wsUri].
String _singleInstance(String wsUri) => "[${_instance(wsUri)}]";

void main() {
  group("DtdInstance", () {
    test("exposes its fields", () {
      const DtdInstance instance = DtdInstance(
        wsUri: "ws://localhost:4444/dtd",
        dartVersion: "3.9.0",
        workspaceRoot: "/tmp/ws",
        pid: 42,
        ideName: "IntelliJ",
      );
      expect(instance.wsUri, "ws://localhost:4444/dtd");
      expect(instance.dartVersion, "3.9.0");
      expect(instance.workspaceRoot, "/tmp/ws");
      expect(instance.pid, 42);
      expect(instance.ideName, "IntelliJ");
    });
  });

  group("DiscoveredApp", () {
    test("exposes its fields", () {
      const DiscoveredApp app = DiscoveredApp(
        name: "clockwork",
        appUri: "ws://localhost:8181/",
        dtdUri: "ws://localhost:4444/dtd",
      );
      expect(app.name, "clockwork");
      expect(app.appUri, "ws://localhost:8181/");
      expect(app.dtdUri, "ws://localhost:4444/dtd");
    });
  });

  group("listDtdInstances", () {
    test("parses the machine output", () async {
      final File script = await _printFixture(
        '[{"wsUri": "ws://a", "dartVersion": "3.9.0", '
        '"workspaceRoot": "/tmp/a", "pid": 1, "ideName": "VsCode"}, '
        '{"wsUri": "ws://b", "dartVersion": "3.8.0", '
        '"workspaceRoot": "/tmp/b"}]',
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      final List<DtdInstance> instances = await discovery.listDtdInstances();
      expect(instances, hasLength(2));
      expect(instances.first.wsUri, "ws://a");
      expect(instances.first.dartVersion, "3.9.0");
      expect(instances.first.pid, 1);
      expect(instances.first.ideName, "VsCode");
      expect(instances.last.pid, isNull);
      expect(instances.last.ideName, isNull);
    });

    test("throws a StateError when the listing fails", () async {
      final File script = await _failingFixture();
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      await expectLater(
        discovery.listDtdInstances(),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            "message",
            contains("boom"),
          ),
        ),
      );
    });

    test("throws a StateError on invalid JSON", () async {
      final File script = await _printFixture("not json");
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      await expectLater(
        discovery.listDtdInstances(),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            "message",
            contains("not valid JSON"),
          ),
        ),
      );
    });

    test("returns no instances for a non-list payload", () async {
      final File script = await _printFixture('{"nope": true}');
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      expect(await discovery.listDtdInstances(), isEmpty);
    });

    test("skips entries that are not objects", () async {
      final File script = await _printFixture(
        '["ignored", {"wsUri": "ws://a", "dartVersion": "3.9.0", '
        '"workspaceRoot": "/tmp/a"}]',
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      final List<DtdInstance> instances = await discovery.listDtdInstances();
      expect(instances, hasLength(1));
      expect(instances.single.wsUri, "ws://a");
    });
  });

  group("discoverApps", () {
    test("returns the apps advertised by reachable DTDs", () async {
      final FakeWireServer server = await FakeWireServer.start(
        (Map<String, Object?> request) async {
          expect(request["method"], "ConnectedApp.getVmServices");
          return <String, Object?>{
            "type": "VmServicesResponse",
            "vmServices": <Map<String, Object?>>[
              <String, Object?>{"uri": "ws://app1:8181/", "name": "clockwork"},
              <String, Object?>{"uri": "ws://app2:8181/"},
            ],
          };
        },
      );
      addTearDown(server.close);
      final File script = await _printFixture(
        _singleInstance(server.uri.toString()),
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      final List<DiscoveredApp> apps = await discovery.discoverApps();
      expect(apps, hasLength(2));
      expect(apps.first.name, "clockwork");
      expect(apps.first.appUri, "ws://app1:8181/");
      expect(apps.first.dtdUri, server.uri.toString());
      expect(apps.last.name, "app@app2:8181");
      expect(apps.last.appUri, "ws://app2:8181/");
    });

    test("prefers the exposed URI", () async {
      final FakeWireServer server = await FakeWireServer.start(
        (Map<String, Object?> request) async {
          return <String, Object?>{
            "type": "VmServicesResponse",
            "vmServices": <Map<String, Object?>>[
              <String, Object?>{
                "uri": "ws://internal:8181/",
                "exposedUri": "ws://exposed:8383/",
              },
            ],
          };
        },
      );
      addTearDown(server.close);
      final File script = await _printFixture(
        _singleInstance(server.uri.toString()),
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      final List<DiscoveredApp> apps = await discovery.discoverApps();
      expect(apps.single.appUri, "ws://exposed:8383/");
      expect(apps.single.name, "app@exposed:8383");
    });

    test("restricts discovery to the given dtdUri", () async {
      final FakeWireServer server = await FakeWireServer.start(
        (Map<String, Object?> request) async {
          return <String, Object?>{
            "type": "VmServicesResponse",
            "vmServices": <Map<String, Object?>>[
              <String, Object?>{"uri": "ws://app1:8181/", "name": "clockwork"},
            ],
          };
        },
      );
      addTearDown(server.close);
      final File script = await _printFixture(
        '[{"wsUri": "ws://elsewhere:4444/dtd", "dartVersion": "3.9.0", '
        '"workspaceRoot": "/tmp"},'
        "${_instance(server.uri.toString())}]",
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      final List<DiscoveredApp> apps = await discovery.discoverApps(
        dtdUri: server.uri.toString(),
      );
      expect(apps, hasLength(1));
      expect(apps.single.name, "clockwork");
    });

    test("skips DTDs that refuse to connect", () async {
      final File script = await _printFixture(
        '[{"wsUri": "ws://127.0.0.1:1/never", "dartVersion": "3.9.0", '
        '"workspaceRoot": "/tmp"}]',
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      expect(await discovery.discoverApps(), isEmpty);
    });

    test("skips DTDs that fail the app lookup", () async {
      final FakeWireServer server = await FakeWireServer.start(
        (Map<String, Object?> request) async {
          throw StateError("app lookup unavailable");
        },
      );
      addTearDown(server.close);
      final File script = await _printFixture(
        _singleInstance(server.uri.toString()),
      );
      final ArcaneAppDiscovery discovery = ArcaneAppDiscovery(
        dartExecutable: script.path,
      );
      expect(await discovery.discoverApps(), isEmpty);
    });
  });
}
