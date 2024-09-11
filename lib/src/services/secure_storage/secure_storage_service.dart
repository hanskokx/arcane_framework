import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:get_it/get_it.dart";

/// A singleton class that provides secure storage functionality using
/// `FlutterSecureStorage`.
///
/// The `ArcaneSecureStorage` class is responsible for securely storing and
/// retrieving key-value pairs, such as user email and install IDs. It supports
/// caching for certain keys and provides initialization, deletion, and
/// read/write methods for interacting with the secure storage.
class ArcaneSecureStorage {
  /// The singleton instance of `ArcaneSecureStorage`.
  static final ArcaneSecureStorage _instance = ArcaneSecureStorage._internal();

  /// Provides access to the singleton instance of `ArcaneSecureStorage`.
  static ArcaneSecureStorage get I => _instance;

  ArcaneSecureStorage._internal();

  /// The underlying secure storage instance.
  ///
  /// This is initialized with `FlutterSecureStorage`, using encrypted shared
  /// preferences for Android.
  late final FlutterSecureStorage _storage;

  /// Caches the user's email in memory.
  ///
  /// This is used to reduce the number of reads to secure storage for the email
  /// key.
  String? _emailCache;

  /// Provides access to the cached email if it exists.
  String? get cachedEmail => _emailCache;

  /// The key used to store and retrieve the email from secure storage.
  static const String emailKey = "email";

  /// The key used to store and retrieve the install ID from secure storage.
  static const String installIdKey = "installId";

  /// Indicates whether the secure storage has been initialized.
  bool _initialized = false;

  /// Returns `true` if the secure storage has been initialized.
  bool get initialized => I._initialized;

  /// Initializes the secure storage and registers it with `GetIt` for
  /// dependency injection.
  ///
  /// This method sets up the `FlutterSecureStorage` with encrypted shared
  /// preferences for Android, and registers it under the instance name
  /// `ArcaneSecureStorage`. It also sets the initialized flag to `true`.
  ArcaneSecureStorage init() {
    GetIt.I.registerSingleton<FlutterSecureStorage>(
      instanceName: "ArcaneSecureStorage",
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      ),
    );
    I._storage = GetIt.I<FlutterSecureStorage>(
      instanceName: "ArcaneSecureStorage",
    );
    I._initialized = true;
    return I;
  }

  /// Deletes all key-value pairs stored in secure storage.
  ///
  /// This method clears the cache and deletes all data stored in the secure\
  /// storage. It returns `true` on success and `false` on failure.
  ///
  /// Example:
  /// ```dart
  /// bool success = await ArcaneSecureStorage.I.deleteAll();
  /// ```
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

  /// Retrieves a value associated with the given [key] from secure storage.
  ///
  /// If the [key] is `emailKey`, the value will be cached in memory for future
  /// use.
  /// This method returns `null` if the key is not found or if an error occurs.
  ///
  /// Example:
  /// ```dart
  /// String? email = await ArcaneSecureStorage.I.getValue(ArcaneSecureStorage.emailKey);
  /// ```
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

  /// Writes the given [value] associated with the [key] to secure storage.
  ///
  /// This method returns `true` on success and `false` on failure.
  ///
  /// Example:
  /// ```dart
  /// bool success = await ArcaneSecureStorage.I.setValue(ArcaneSecureStorage.emailKey, "user@example.com");
  /// ```
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
