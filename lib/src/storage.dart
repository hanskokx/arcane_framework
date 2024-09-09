import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

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

  ArcaneSecureStorage init(FlutterSecureStorage storage) {
    I._storage = storage;
    I._initialized = true;
    return I;
  }

  Future<bool> deleteAll() async {
    try {
      _emailCache = null;
      await _storage.deleteAll();

      return true;
    } catch (exception) {
      return false;
    }
  }

  Future<String?> getValue(String key) async {
    String? value;

    try {
      value = await _storage.read(key: key);
      if (value.isNullOrEmpty) {
        Arcane.logger.log(
          "Value retrieved from secure storage is empty",
          level: Level.info,
          metadata: {
            "key": key,
          },
        );
      }

      // Cache the email for future use
      if (key == emailKey) _emailCache = value;

      Arcane.logger.log(
        "Successfully retrived value from secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
          if (kDebugMode) "value": "$value",
        },
      );
    } catch (e) {
      Arcane.logger.log(
        "Unable to retrieve value from secure storage",
        level: Level.error,
        metadata: {
          "key": key,
        },
      );
    }

    return value;
  }

  Future<bool> setValue(String key, String? value) async {
    Arcane.logger.log(
      "Setting value in secure storage",
      level: Level.debug,
      metadata: {
        "key": key,
        if (kDebugMode) "value": "$value",
      },
    );

    try {
      await _storage.write(key: key, value: value);
      // Cache the email for future use
      if (key == emailKey) _emailCache = value;
      Arcane.logger.log(
        "Successfully set value in secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
          if (kDebugMode) "value": "$value",
        },
      );

      return true;
    } catch (e) {
      Arcane.logger.log(
        "Unable to set value in secure storage",
        level: Level.error,
        metadata: {
          "key": key,
          if (kDebugMode) "value": "$value",
        },
      );
      return false;
    }
  }
}
