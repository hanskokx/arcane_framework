import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";
import "package:uuid/uuid.dart";

part "id_enums.dart";

/// A singleton service that manages unique IDs, including install and session IDs.
///
/// The `ArcaneIdService` provides a way to generate and retrieve unique identifiers
/// for application installs and sessions. It interacts with secure storage to persist
/// the install ID across app launches and generates new session IDs for each session.
class ArcaneIdService extends ArcaneService {
  /// Whether the service is mocked for testing purposes.
  static bool _mocked = false;

  /// The singleton instance of `ArcaneIdService`.
  static final ArcaneIdService _instance = ArcaneIdService._internal();

  /// Provides access to the singleton instance of `ArcaneIdService`.
  static ArcaneIdService get I => _instance;

  ArcaneIdService._internal();

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Returns `true` if the service has been initialized.
  bool get initialized => I._initialized;

  /// The unique install ID.
  ///
  /// This ID is persisted across app launches and is used to uniquely identify
  /// the installation of the app.
  String? _installId;

  /// Retrieves the install ID.
  ///
  /// If the install ID is not yet initialized, this method initializes the service
  /// and generates a new ID if necessary.
  ///
  /// Example:
  /// ```dart
  /// String? id = await ArcaneIdService.I.installId;
  /// ```
  Future<String?> get installId async {
    if (!initialized) await _init();
    return I._installId;
  }

  /// The unique session ID.
  ///
  /// This ID is generated for each app session and is used to uniquely identify
  /// the current session.
  String? _sessionId;

  /// Retrieves the session ID.
  ///
  /// If the session ID is not yet initialized, this method initializes the service
  /// and generates a new session ID.
  ///
  /// Example:
  /// ```dart
  /// String? sessionId = await ArcaneIdService.I.sessionId;
  /// ```
  Future<String?> get sessionId async {
    if (!initialized) await _init();
    return I._sessionId;
  }

  /// Generates a new unique ID.
  ///
  /// This method uses UUID version 7 to generate a new unique ID.
  String get newId => uuid.v7();

  /// The `Uuid` instance used for generating unique IDs.
  static const Uuid uuid = Uuid();

  /// Initializes the `ArcaneIdService`.
  ///
  /// This method retrieves the install ID from secure storage, generating and storing a new
  /// one if it does not exist. It also generates a new session ID.
  ///
  /// Example:
  /// ```dart
  /// await ArcaneIdService.I._init();
  /// ```
  Future<ArcaneIdService> _init() async {
    if (_mocked) return I;
    if (!Arcane.storage.initialized) Arcane.storage.init();

    I._installId = await Arcane.storage.getValue(
      ArcaneSecureStorage.installIdKey,
    );

    if (I._installId == null) {
      // Generate a new ID and store it
      I._installId = uuid.v7();
      await Arcane.storage.setValue(
        ArcaneSecureStorage.installIdKey,
        I._installId,
      );
    }

    I._sessionId = uuid.v7();
    I._initialized = true;
    return I;
  }

  /// Sets the service as mocked for testing purposes.
  ///
  /// When the service is mocked, it bypasses certain initializations and uses
  /// mocked data for testing.
  @visibleForTesting
  static void setMocked() => _mocked = true;
}
