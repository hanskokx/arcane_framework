import "dart:async";
import "dart:convert";
import "dart:developer";

import "package:arcane_framework/src/arcane.dart";
import "package:arcane_framework/src/mcp/protocol.dart";
import "package:arcane_framework/src/service/arcane_service.dart";
import "package:arcane_framework/src/services/authentication/authentication_service.dart";
import "package:arcane_framework/src/services/environment/environment_interface.dart";
import "package:arcane_framework/src/services/environment/environment_service.dart";
import "package:arcane_framework/src/services/feature_flags/feature_flags_service.dart";
import "package:arcane_framework/src/services/logging/logging_service.dart";
import "package:arcane_framework/src/services/theme/theme_service.dart";
import "package:flutter/foundation.dart";

import "arcane_log_buffer.dart";

/// A handler for one method exposed through the runtime service extension.
///
/// Implementations return a JSON-encodable payload or throw for an invalid
/// invocation; errors are reported to the caller as an `error` response.
typedef ArcaneDevtoolsMethodHandler =
    Future<Object?> Function(
      Map<String, Object?> params,
    );

/// Internal registration of arcane_framework's runtime service extension.
///
/// Registers the single [arcaneMcpServiceExtension] service extension that
/// exposes live runtime state over the VM service to both the DevTools
/// extension and the bundled MCP server ([ArcaneMcpServer]). Every invocation
/// returns
/// `{"type": "result", "result": ...}` or `{"type": "error", "error": "..."}`
/// (see [arcaneMcpBuildResult]/[arcaneMcpBuildError]). The extension is
/// registered automatically when an app mounts `ArcaneApp` in a debug build;
/// profile and release builds never register it ([kDebugMode] guard). This
/// class is internal to the framework and not part of the public API.
abstract final class ArcaneServiceExtensions {
  /// The VM service extension registered by the framework.
  static const String serviceExtension = arcaneMcpServiceExtension;

  static bool _registered = false;

  static final ArcaneLogBuffer _logBuffer = ArcaneLogBuffer();

  /// The rolling buffer of recent log events collected by the framework.
  ///
  /// Internal; exposed for tests.
  @visibleForTesting
  static ArcaneLogBuffer get logBuffer => _logBuffer;

  static final Map<String, ArcaneDevtoolsMethodHandler> _methods =
      <String, ArcaneDevtoolsMethodHandler>{};

  /// Registers the runtime service extension for this isolate.
  ///
  /// No-op in non-debug builds; the extension (and its log buffer) are only
  /// registered when [kDebugMode] is true, so live runtime state is never
  /// exposed on the VM service in profile or release apps. Safe to call
  /// multiple times (for example across hot reloads); duplicate registrations
  /// are ignored. The log buffer is re-attached whenever it is missing, so
  /// calling [register] again after [ArcaneLogger.reset] restores log capture.
  static void register() {
    if (!kDebugMode) return;
    if (!Arcane.logger.interfaces.contains(_logBuffer)) {
      unawaited(Arcane.logger.registerInterface(_logBuffer));
    }
    if (_registered) return;
    _registered = true;

    _registerMethod(
      ArcaneMcpMethods.ping,
      (Map<String, Object?> __) async => <String, Object?>{
        "status": "ok",
        "extension": serviceExtension,
      },
    );

    _registerMethod(ArcaneMcpMethods.overview, (Map<String, Object?> __) async {
      return <String, Object?>{
        "app": "arcane_framework",
        "services": _serviceNames(),
        "serviceSummaries": _serviceSummaries(),
        "logging": _loggingPayload(),
        "recentLogs": _logBuffer.snapshot(limit: 50),
        "featureFlags": _featureFlagsPayload(),
        "auth": await _authenticationPayload(const <String, Object?>{}),
        "theme": _themePayload(),
        "environment": _environmentPayload(),
      };
    });

    _registerMethod(
      ArcaneMcpMethods.services,
      (Map<String, Object?> __) async => <String, Object?>{
        "services": _serviceSummaries(),
      },
    );

    _registerMethod(ArcaneMcpMethods.logs, (Map<String, Object?> params) async {
      final List<Map<String, Object?>> logs = _logBuffer.snapshot(
        minimumLevel: _levelFromName(params[ArcaneMcpParams.level]?.toString()),
        module: params[ArcaneMcpParams.module]?.toString() ?? "",
        search: params[ArcaneMcpParams.search]?.toString() ?? "",
        limit: params[ArcaneMcpParams.limit] as int?,
      );
      return <String, Object?>{"count": logs.length, "logs": logs};
    });

    _registerMethod(
      ArcaneMcpMethods.featureFlags,
      (Map<String, Object?> __) async => _featureFlagsPayload(),
    );

    _registerMethod(
      ArcaneMcpMethods.setFeatureFlag,
      (Map<String, Object?> params) async => _setFeatureFlagPayload(params),
    );

    _registerMethod(
      ArcaneMcpMethods.authentication,
      (Map<String, Object?> params) async => _authenticationPayload(params),
    );

    _registerMethod(
      ArcaneMcpMethods.theme,
      (Map<String, Object?> __) async => _themePayload(),
    );

    _registerMethod(
      ArcaneMcpMethods.setThemeMode,
      (Map<String, Object?> params) async => arcaneThemeDevToolsSetMode(params),
    );

    _registerMethod(
      ArcaneMcpMethods.environment,
      (Map<String, Object?> __) async => _environmentPayload(),
    );

    _registerMethod(
      ArcaneMcpMethods.setEnvironment,
      (Map<String, Object?> params) async => _setEnvironmentPayload(params),
    );

    _registerMethod(
      ArcaneMcpMethods.setAuthStatus,
      (Map<String, Object?> params) async {
        switch (params["status"]) {
          case "authenticated":
            Arcane.auth.setAuthenticated();
          case "unauthenticated":
            Arcane.auth.setUnauthenticated();
          default:
            throw ArgumentError.value(
              params["status"],
              "status",
              "Expected one of: authenticated, unauthenticated.",
            );
        }
        return _authenticationPayload(const <String, Object?>{});
      },
    );

    _register(serviceExtension, _handleInvoke);
  }

  static void _registerMethod(
    String method,
    ArcaneDevtoolsMethodHandler handler,
  ) {
    _methods[method] = handler;
  }

  static Future<ServiceExtensionResponse> _handleInvoke(
    String method,
    Map<String, String> parameters,
  ) async {
    final Map<String, Object?> response = await handle(parameters);
    return ServiceExtensionResponse.result(jsonEncode(response));
  }

  /// Handles a service extension invocation and returns the wire response as
  /// produced by [arcaneMcpBuildResult] or [arcaneMcpBuildError].
  ///
  /// This is the pure dispatch path used by [_handleInvoke]; tests can call it
  /// directly without a live VM service.
  @visibleForTesting
  static Future<Map<String, Object?>> handle(
    Map<String, String> parameters,
  ) async {
    try {
      final String target = parameters[arcaneMcpMethodParameter] ?? "";
      final Map<String, Object?> params = _decodeParams(
        parameters[arcaneMcpParamsParameter],
      );
      final ArcaneDevtoolsMethodHandler? handler = _methods[target];
      if (handler == null) {
        return arcaneMcpBuildError(
          'Unknown method "$target".',
        );
      }
      final Object? result = await handler(params);
      return arcaneMcpBuildResult(result);
    } catch (error) {
      return arcaneMcpBuildError(error.toString());
    }
  }

  static void _register(String extension, ServiceExtensionHandler handler) {
    try {
      registerExtension(extension, handler);
    } on ArgumentError {
      // Already registered (e.g. across a hot reload). Ignore.
    }
  }

  static Map<String, Object?> _decodeParams(String? raw) {
    if (raw == null) return const <String, Object?>{};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw ArgumentError(
        'The "$arcaneMcpParamsParameter" parameter must be valid JSON.',
      );
    }
    if (decoded is Map<String, Object?>) return decoded;
    throw ArgumentError(
      'The "$arcaneMcpParamsParameter" parameter must be a JSON object.',
    );
  }

  static List<String> _serviceNames() => <String>[
    for (final ArcaneService service in Arcane.services)
      service.runtimeType.toString(),
  ];

  static List<Map<String, Object?>> _serviceSummaries() =>
      <Map<String, Object?>>[
        for (final ArcaneService service in Arcane.services)
          _serviceSummary(service),
      ];

  static Map<String, Object?> _serviceSummary(ArcaneService service) {
    final Map<String, Object?> summary = <String, Object?>{
      "type": "${service.runtimeType}",
    };
    if (service is ArcaneFeatureFlagService) {
      summary.addAll(<String, Object?>{
        "enabledFeatures": service.enabledFeatures.length,
      });
    } else if (service is ArcaneAuthenticationService) {
      summary.addAll(<String, Object?>{"status": service.status.name});
    } else if (service is ArcaneThemeService) {
      summary.addAll(<String, Object?>{
        "themeMode": service.currentThemeMode.name,
      });
    } else if (service is ArcaneEnvironmentService) {
      summary.addAll(<String, Object?>{"environment": service.current.name});
    }
    return summary;
  }

  static Map<String, Object?> _loggingPayload() {
    final ArcaneLogger logger = Arcane.logger;
    return <String, Object?>{
      "initialized": logger.initialized,
      "interfaces": <String>[
        for (final LoggingInterface interface in logger.interfaces)
          "${interface.runtimeType}",
      ],
      "metadata": logger.additionalMetadata,
      "additionalMetadata": logger.additionalMetadata,
    };
  }

  static Map<String, Object?> _featureFlagsPayload() {
    final ArcaneFeatureFlagService features = Arcane.features;
    final List<Enum> enabled = features.enabledFeatures;
    return <String, Object?>{
      "initialized": ArcaneFeatureFlagService.initialized,
      "enabled": <String>[for (final Enum flag in enabled) flag.name],
      "catalog": <Map<String, Object?>>[
        for (final Enum feature in features.catalog)
          <String, Object?>{
            "name": feature.name,
            "type": _enumTypeName(feature),
            "enabled": enabled.contains(feature),
          },
      ],
    };
  }

  static Map<String, Object?> _setFeatureFlagPayload(
    Map<String, Object?> params,
  ) {
    final String name = params[ArcaneMcpParams.name]?.toString() ?? "";
    final bool enabled = params[ArcaneMcpParams.enabled] as bool? ?? true;
    if (name.isEmpty) {
      throw ArgumentError(
        'The "name" parameter is required to toggle a feature flag.',
      );
    }
    Enum? feature;
    for (final Enum candidate in Arcane.features.catalog) {
      if (candidate.name == name) {
        feature = candidate;
        break;
      }
    }
    if (feature == null) {
      throw ArgumentError(
        'No feature flag named "$name" is known to the framework. Flags '
        "become known when the app enables or disables them in code with "
        "Arcane.features.enableFeature/disableFeature.",
      );
    }
    final ArcaneFeatureFlagService features = Arcane.features;
    if (enabled) {
      features.enableFeature(feature);
    } else {
      features.disableFeature(feature);
    }
    return <String, Object?>{
      "name": feature.name,
      "type": _enumTypeName(feature),
      "enabled": features.isEnabled(feature),
    };
  }

  static Future<Map<String, Object?>> _authenticationPayload(
    Map<String, Object?> params,
  ) async {
    final ArcaneAuthenticationService auth = Arcane.auth;
    final String? accessToken = await auth.accessToken;
    final String? refreshToken = await auth.refreshToken;
    final bool includeTokens = params[ArcaneMcpParams.includeTokens] == true;
    return <String, Object?>{
      "status": auth.status.name,
      "authenticated": auth.isAuthenticated,
      "signedIn": auth.isSignedIn.value,
      "isSignedIn": auth.isSignedIn.value,
      "interfaceType": "${auth.authInterface?.runtimeType}",
      "hasAccessToken": accessToken != null && accessToken.isNotEmpty,
      "hasRefreshToken": refreshToken != null && refreshToken.isNotEmpty,
      if (includeTokens) "accessToken": accessToken,
      if (includeTokens) "refreshToken": refreshToken,
    };
  }

  static Map<String, Object?> _themePayload() => arcaneThemeDevToolsState();

  static Map<String, Object?> _environmentPayload() {
    final Environment environment = Arcane.environment.current;
    return <String, Object?>{
      "name": environment.name,
      "debug": environment.isDebug,
      "isDebug": environment.isDebug,
    };
  }

  static Map<String, Object?> _setEnvironmentPayload(
    Map<String, Object?> params,
  ) {
    final String name = params[ArcaneMcpParams.name]?.toString() ?? "";
    if (name.isEmpty) {
      throw ArgumentError(
        'The "name" parameter is required to set the environment.',
      );
    }
    final Environment environment = switch (name) {
      "debug" => Environment.debug,
      "normal" => Environment.normal,
      _ => Environment(name),
    };
    Arcane.environment.setEnvironment(environment);
    return _environmentPayload();
  }

  static Level _levelFromName(String? name) {
    if (name == null) return Level.all;
    for (final Level level in Level.values) {
      if (level.name == name) return level;
    }
    return Level.all;
  }

  static String _enumTypeName(Enum value) => value.toString().split(".").first;
}
