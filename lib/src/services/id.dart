import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";
import "package:uuid/uuid.dart";

class ArcaneIdService extends ArcaneService {
  static bool _mocked = false;
  static final ArcaneIdService _instance = ArcaneIdService._internal();

  static ArcaneIdService get I => _instance;

  ArcaneIdService._internal();

  bool _initialized = false;
  bool get initialized => I._initialized;

  String? _installId;
  Future<String?> get installId async {
    if (!initialized) await _init();
    return I._installId;
  }

  String? _sessionId;
  Future<String?> get sessionId async {
    if (!initialized) await _init();
    return I._sessionId;
  }

  String get newId => uuid.v7();

  static const Uuid uuid = Uuid();

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

  @visibleForTesting
  static void setMocked() => _mocked = true;
}

enum ID {
  session,
  install,
}
