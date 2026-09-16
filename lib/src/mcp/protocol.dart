/// The wire protocol shared between arcane_framework's runtime service
/// extension (registered when `ArcaneApp` mounts) and the standalone MCP
/// server ([ArcaneMcpServer]).
///
/// This library is pure Dart with no Flutter or runtime dependencies so that
/// the MCP server can run on the Dart VM (`dart run`, `dart compile exe`)
/// without a Flutter toolchain. It defines:
///
/// * The VM service extension name and the JSON parameter keys used to call it
///   ([arcaneMcpServiceExtension], [arcaneMcpMethodParameter],
///   [arcaneMcpParamsParameter]).
/// * The method and parameter names shared by the framework's extension and
///   the server tools ([ArcaneMcpMethods], [ArcaneMcpParams]).
/// * The response model and codec ([ArcaneMcpResponse], [arcaneMcpDecode],
///   [arcaneMcpBuildResult], [arcaneMcpBuildError]).
library;

import "dart:convert";

/// The VM service extension exposed by arcane_framework in the app.
///
/// arcane_framework registers this extension automatically when the app mounts
/// `ArcaneApp`. The MCP server invokes it (via `callServiceExtension`) to ask
/// the running app for state and to apply simple mutations; the DevTools
/// extension uses the same extension.
const String arcaneMcpServiceExtension = "ext.arcane.devtools.invoke";

/// The parameter key carrying the method name to invoke.
const String arcaneMcpMethodParameter = "method";

/// The parameter key carrying the JSON-encoded arguments for the method.
const String arcaneMcpParamsParameter = "params";

/// The names of the methods accepted by the summary bridge extension.
abstract final class ArcaneMcpMethods {
  /// Health check that always responds with `{"status": "ok"}`.
  static const String ping = "ping";

  /// The app and service summary: registered services plus logger state.
  static const String overview = "overview";

  /// The list of registered [ArcaneService]s with a summary of each.
  static const String services = "services";

  /// Recent log events, optionally filtered by level, module, or search
  /// text, and limited by `limit`.
  static const String logs = "logs";

  /// The feature flag state: enabled flags plus the known flags.
  static const String featureFlags = "feature_flags";

  /// Enables or disables a known feature flag by `name`.
  static const String setFeatureFlag = "set_feature_flag";

  /// The authentication state.
  static const String authentication = "authentication";

  /// The theme state: current mode, brightness, and theme colors.
  static const String theme = "theme";

  /// Sets the theme mode to "light", "dark", or "system".
  static const String setThemeMode = "set_theme_mode";

  /// The current application environment.
  static const String environment = "environment";

  /// Sets the application environment by `name`.
  static const String setEnvironment = "set_environment";

  /// Sets the authentication status (used by the DevTools extension).
  static const String setAuthStatus = "set_auth_status";
}

/// The parameter keys shared between the MCP server tools and the bridge.
abstract final class ArcaneMcpParams {
  /// The name of the connected app to target (server-side only).
  static const String appName = "appName";

  /// The VM service URI of the app to target (server-side only).
  static const String appUri = "appUri";

  /// The DTD `wsUri` to restrict discovery to (server-side only).
  static const String dtdUri = "dtdUri";

  /// A VM service URI to connect to directly (server-side only).
  static const String vmServiceUri = "vmServiceUri";

  /// A name used by `feature_flags`, `set_feature_flag`, and
  /// `set_environment`.
  static const String name = "name";

  /// A boolean used by `set_feature_flag`.
  static const String enabled = "enabled";

  /// A theme mode ("light", "dark", or "system") used by `set_theme_mode`.
  static const String mode = "mode";

  /// A minimum log level name used by `logs`.
  static const String level = "level";

  /// A module-name filter used by `logs`.
  static const String module = "module";

  /// A message search string used by `logs`.
  static const String search = "search";

  /// The maximum number of log entries used by `logs`.
  static const String limit = "limit";

  /// Whether `authentication` should include access and refresh tokens.
  static const String includeTokens = "includeTokens";
}

/// The decoded result of a service extension invocation.
sealed class ArcaneMcpResponse {
  const ArcaneMcpResponse();
}

/// A successful invocation carrying the JSON-encodable [data].
class ArcaneMcpOkResponse extends ArcaneMcpResponse {
  const ArcaneMcpOkResponse(this.data);

  /// The JSON-encodable result payload.
  final Object? data;
}

/// A failed invocation carrying a human-readable [message].
class ArcaneMcpErrorResponse extends ArcaneMcpResponse {
  const ArcaneMcpErrorResponse(this.message);

  /// A human-readable description of the failure.
  final String message;
}

/// Builds the wire response for a successful bridge invocation.
Map<String, Object?> arcaneMcpBuildResult(Object? data) => <String, Object?>{
  "type": "result",
  "result": data,
};

/// Builds the wire response for a failed bridge invocation.
Map<String, Object?> arcaneMcpBuildError(String message) => <String, Object?>{
  "type": "error",
  "error": message,
};

/// Decodes a JSON response produced by [arcaneMcpBuildResult] or
/// [arcaneMcpBuildError].
ArcaneMcpResponse arcaneMcpDecode(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const ArcaneMcpErrorResponse(
      "Bridge response body was not valid JSON.",
    );
  }
  if (decoded is! Map<String, Object?>) {
    return const ArcaneMcpErrorResponse(
      "Bridge response body was not a JSON object.",
    );
  }
  return switch (decoded["type"]) {
    "result" => ArcaneMcpOkResponse(decoded["result"]),
    "error" => ArcaneMcpErrorResponse(
      decoded["error"]?.toString() ?? "Unknown bridge error.",
    ),
    _ => const ArcaneMcpErrorResponse(
      "Bridge response had an unknown type.",
    ),
  };
}
