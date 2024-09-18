import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:uuid/uuid.dart";

class IdService extends ArcaneService {
  static final IdService _instance = IdService._internal();
  static IdService get I => _instance;

  IdService._internal();

  bool _initialized = false;
  bool get initialized => I._initialized;

  String? _sessionId;
  ValueListenable<String?> get sessionId =>
      ValueNotifier<String?>(I._sessionId);

  String get newId => uuid.v7();

  /// The `Uuid` instance used for generating unique IDs.
  static const Uuid uuid = Uuid();

  Future<void> init() async {
    Arcane.log(
      "Initializing ID Service",
      level: Level.debug,
    );

    I._sessionId = uuid.v7();
    I._initialized = true;
    notifyListeners();
  }
}
