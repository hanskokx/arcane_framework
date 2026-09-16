import "dart:convert";
import "dart:io";

import "package:dtd/dtd.dart";

/// Metadata about a running Dart Tooling Daemon, discovered with
/// `dart tooling-daemon --list`.
class DtdInstance {
  const DtdInstance({
    required this.wsUri,
    required this.dartVersion,
    required this.workspaceRoot,
    this.pid,
    this.ideName,
  });

  /// The WebSocket URI used to connect to the DTD.
  final String wsUri;

  /// The Dart version of the DTD process.
  final String dartVersion;

  /// The workspace root the DTD was launched from.
  final String workspaceRoot;

  /// The process id of the DTD, when reported.
  final int? pid;

  /// The IDE name that launched the DTD, when known.
  final String? ideName;
}

/// A running app whose VM service is advertised by a DTD instance.
class DiscoveredApp {
  const DiscoveredApp({
    required this.name,
    required this.appUri,
    required this.dtdUri,
  });

  /// The display name reported by the DTD, or a location-based fallback.
  final String name;

  /// The VM service URI to connect to.
  final String appUri;

  /// The DTD `wsUri` that advertised this app.
  final String dtdUri;
}

/// Discovers running apps via the Dart Tooling Daemon.
///
/// The DTD tracks every VM service that is launched with the Dart part of a
/// Flutter (or Dart) app, which is how editors and DevTools find running apps.
class ArcaneAppDiscovery {
  /// Creates a discovery that shells out to [dartExecutable] (defaults to the
  /// current Dart executable) to list DTD instances.
  ArcaneAppDiscovery({String? dartExecutable})
    : _dartExecutable = dartExecutable ?? Platform.resolvedExecutable;

  final String _dartExecutable;

  /// Lists every DTD instance registered with `dart tooling-daemon`.
  Future<List<DtdInstance>> listDtdInstances() async {
    final ProcessResult result = await Process.run(
      _dartExecutable,
      const <String>["tooling-daemon", "--list", "--machine"],
    );
    if (result.exitCode != 0) {
      throw StateError(
        "Failed to list Dart Tooling Daemons: ${result.stderr}",
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(result.stdout as String);
    } on FormatException {
      throw StateError("tooling-daemon output was not valid JSON.");
    }
    if (decoded is! List) return const <DtdInstance>[];
    return <DtdInstance>[
      for (final Object? item in decoded)
        if (item is Map)
          DtdInstance(
            wsUri: item["wsUri"]?.toString() ?? "",
            dartVersion: item["dartVersion"]?.toString() ?? "",
            workspaceRoot: item["workspaceRoot"]?.toString() ?? "",
            pid: item["pid"] as int?,
            ideName: item["ideName"]?.toString(),
          ),
    ];
  }

  /// Discovers the apps advertised by every reachable DTD instance.
  ///
  /// When [dtdUri] is provided, only the DTD with that `wsUri` is queried.
  /// Instances that are unreachable or refuse the app lookup are skipped.
  Future<List<DiscoveredApp>> discoverApps({String? dtdUri}) async {
    final List<DtdInstance> instances = await listDtdInstances();
    final List<DiscoveredApp> apps = <DiscoveredApp>[];
    for (final DtdInstance instance in instances) {
      if (dtdUri != null && instance.wsUri != dtdUri) continue;
      final DartToolingDaemon? dtd = await _tryConnect(instance.wsUri);
      if (dtd == null) continue;
      try {
        final VmServicesResponse services = await dtd.getVmServices();
        for (final VmServiceInfo info in services.vmServicesInfos) {
          final String appUri = info.exposedUri ?? info.uri;
          final String name =
              info.name ??
              "app@${Uri.parse(appUri).host}:${Uri.parse(appUri).port}";
          apps.add(
            DiscoveredApp(name: name, appUri: appUri, dtdUri: instance.wsUri),
          );
        }
      } on Exception {
        // The DTD did not support the app lookup; skip it.
      } finally {
        await dtd.close();
      }
    }
    return apps;
  }

  Future<DartToolingDaemon?> _tryConnect(String wsUri) async {
    try {
      return await DartToolingDaemon.connect(Uri.parse(wsUri));
    } on Exception {
      return null;
    }
  }
}
