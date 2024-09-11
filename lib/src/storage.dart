import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:get_it/get_it.dart";

class ArcaneSecureStorage {
  static final ArcaneSecureStorage _instance = ArcaneSecureStorage._internal();
  static ArcaneSecureStorage get I => _instance;
  ArcaneSecureStorage._internal();

  late final FlutterSecureStorage _storage;

  String? _emailCache;
  String? get cachedEmail => _emailCache;

  static const String emailKey = "email";
  static const String installIdKey = "installId";

  bool _initialized = false;
  bool get initialized => I._initialized;

  ArcaneSecureStorage init() {
    GetIt.I.registerSingleton<FlutterSecureStorage>(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      ),
      instanceName: "ArcaneSecureStorage",
    );
    I._storage = GetIt.I<FlutterSecureStorage>(
      instanceName: "ArcaneSecureStorage",
    );
    I._initialized = true;
    return I;
  }

  Future<bool> deleteAll() async {
    if (!initialized) init();
    try {
      _emailCache = null;
      await _storage.deleteAll();
      return true;
    } catch (exception) {
      return false;
    }
  }

  Future<String?> getValue(String key) async {
    if (!initialized) init();
    String? value;

    try {
      value = await _storage.read(key: key);
      if (value.isNullOrEmpty) return null;

      // Cache the email for future use
      if (key == emailKey) _emailCache = value;
    } catch (e) {
      throw Exception(e);
    }

    return value;
  }

  Future<bool> setValue(String key, String? value) async {
    if (!initialized) init();

    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (e) {
      return false;
    }
  }
}
