import "package:flutter/foundation.dart";

enum ArcaneFeature {
  /// Enables the [ArcaneLogger] feature.
  logging(true),

  /// Enables debug logging to print to the local debug console
  debugConsoleLogging(kDebugMode),

  /// Enables logging to external services. Requires [ArcaneFeature.logging] to
  /// also be enabled.
  externalLogging(true),

  /// Logs key/value pairs when storing and fetching data from the
  /// [ArcaneSecureStorage]. This is only enabled while in debug mode by
  /// default, as it could potentially expose PII.
  secureStorageLogging(kDebugMode),

  /// Used to allow logins for users defined in [ArcaneConfig.debugAccounts].
  /// These accounts are debug users that are not tied to any real account. If
  /// logged in using a debug account, all APIs will redirect to mocked
  /// data and versions. Some features will be unavailable while logged in with
  /// a debug account.
  accountDebugMode(true),
  ;

  /// Determines whether the given [ArcaneFeatureFeature] is enabled by default.
  final bool enabledAtStartup;

  const ArcaneFeature(this.enabledAtStartup);
}
