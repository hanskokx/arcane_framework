import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";
import "package:uuid/uuid.dart";

class ArcaneIdService extends ArcaneService {
  static bool _mocked = false;
  static final ArcaneIdService _instance = ArcaneIdService._internal();

  static ArcaneIdService get I => _instance;

  ArcaneIdService._internal();

  String? _installId;
  String? get installId => I._installId;

  String? _sessionId;
  String? get sessionId => I._sessionId;

  static const Uuid uuid = Uuid();

  Future<void> init() async {
    if (_mocked) return;

    I._installId =
        await Arcane.storage.getValue(ArcaneSecureStorage.installIdKey);

    if (I._installId == null) {
      // Generate a new ID and store it
      I._installId = uuid.v4();
      await Arcane.storage
          .setValue(ArcaneSecureStorage.installIdKey, I._installId);
    }

    I._sessionId = uuid.v4();
  }

  @visibleForTesting
  static void setMocked() => _mocked = true;
}

enum ID {
  session,
  install,
}
