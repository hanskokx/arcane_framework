import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class ArcaneSecureStorage {
  final FlutterSecureStorage _storage;

  ArcaneSecureStorage(this._storage);

  String? _emailCache;
  String? get cachedEmail => _emailCache;

  static const String emailKey = "email";

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
    if (ArcaneFeature.secureStorageLogging.enabled) {
      Arcane.log(
        "Value requested from secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
        },
      );
    }

    String? value;

    try {
      value = await _storage.read(key: key);
      if (value.isNullOrEmpty && ArcaneFeature.secureStorageLogging.enabled) {
        Arcane.log(
          "Value retrieved from secure storage is empty",
          level: Level.info,
          metadata: {
            "key": key,
          },
        );
      }

      // Cache the email for future use
      if (key == emailKey) _emailCache = value;

      if (ArcaneFeature.secureStorageLogging.enabled) {
        Arcane.log(
          "Successfully retrived value from secure storage",
          level: Level.debug,
          metadata: {
            "key": key,
            if (kDebugMode) "value": "$value",
          },
        );
      }
    } catch (e) {
      Arcane.log(
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
    if (ArcaneFeature.secureStorageLogging.enabled) {
      Arcane.log(
        "Setting value in secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
          "value": "$value",
        },
      );
    }

    try {
      await _storage.write(key: key, value: value);
      // Cache the email for future use
      if (key == emailKey) _emailCache = value;
      if (ArcaneFeature.secureStorageLogging.enabled) {
        Arcane.log(
          "Successfully set value in secure storage",
          level: Level.debug,
          metadata: {
            "key": key,
            if (kDebugMode) "value": "$value",
          },
        );
      }
      return true;
    } catch (e) {
      Arcane.log(
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
