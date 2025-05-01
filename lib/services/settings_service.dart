// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static const String _nytApiKeyPrefix = 'nyt_api_key_';
  static const String _openAqApiKeyPrefix = 'openaq_api_key_';

  static String? _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = (user != null && !user.isAnonymous) ? user.uid : null;
    return uid;
  }

  static String? _getUserSpecificKey(String prefix) {
    final userId = _getCurrentUserId();
    if (userId != null) {
      return '$prefix$userId';
    }
    return null;
  }

  static Future<String?> getNytApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserSpecificKey(_nytApiKeyPrefix);
    if (userKey == null) {
      print(
          '[SettingsService getNytApiKey] Cannot get key: No logged-in user.');
      return null;
    }
    print(
        '[SettingsService getNytApiKey] ====> Attempting to get String for key: $userKey');
    final key = prefs.getString(userKey);
    print(
        '[SettingsService getNytApiKey] <==== Retrieved value for key $userKey: ${key ?? "null"}');
    return key;
  }

  static Future<void> saveNytApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserSpecificKey(_nytApiKeyPrefix);
    if (userKey == null) {
      print(
          '[SettingsService saveNytApiKey] Cannot save key: No logged-in user.');
      return;
    }
    final trimmedKey = key.trim();
    print(
        '[SettingsService saveNytApiKey] Attempting action for userKey $userKey with value: "$trimmedKey"');

    if (trimmedKey.isNotEmpty) {
      print(
          '[SettingsService saveNytApiKey] ====> Setting String for key: $userKey');
      await prefs.setString(userKey, trimmedKey);
      print(
          '[SettingsService saveNytApiKey] <==== SetString successful.');
    } else {
      print(
          '[SettingsService saveNytApiKey] ====> Removing key: $userKey (due to empty input)');
      final bool removed = await prefs.remove(userKey);
      print(
          '[SettingsService saveNytApiKey] <==== Remove action result: $removed');
    }
  }

  static Future<String?> getOpenAqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserSpecificKey(_openAqApiKeyPrefix);
    if (userKey == null) {
      print(
          '[SettingsService getOpenAqApiKey] Cannot get key: No logged-in user.');
      return null;
    }
    print(
        '[SettingsService getOpenAqApiKey] ====> Attempting to get String for key: $userKey');
    final key = prefs.getString(userKey);
    print(
        '[SettingsService getOpenAqApiKey] <==== Retrieved value for key $userKey: ${key ?? "null"}');
    return key;
  }

  static Future<void> saveOpenAqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserSpecificKey(_openAqApiKeyPrefix);
    if (userKey == null) {
      print(
          '[SettingsService saveOpenAqApiKey] Cannot save key: No logged-in user.');
      return;
    }
    final trimmedKey = key.trim();
    print(
        '[SettingsService saveOpenAqApiKey] Attempting action for userKey $userKey with value: "$trimmedKey"');

    if (trimmedKey.isNotEmpty) {
      print(
          '[SettingsService saveOpenAqApiKey] ====> Setting String for key: $userKey');
      await prefs.setString(userKey, trimmedKey);
      print(
          '[SettingsService saveOpenAqApiKey] <==== SetString successful.');
    } else {
      print(
          '[SettingsService saveOpenAqApiKey] ====> Removing key: $userKey (due to empty input)');
      final bool removed = await prefs.remove(userKey);
      print(
          '[SettingsService saveOpenAqApiKey] <==== Remove action result: $removed');
    }
  }

  static Future<void> clearUserSettings(String userId) async {
    if (userId.isEmpty) {
      print(
          '[SettingsService clearUserSettings] Cannot clear settings: Invalid userId provided.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final nytUserKey = '$_nytApiKeyPrefix$userId';
    final openAqUserKey = '$_openAqApiKeyPrefix$userId';
    print(
        '[SettingsService clearUserSettings] ====> Attempting to remove keys: $nytUserKey, $openAqUserKey');
    await Future.wait([
      prefs.remove(nytUserKey),
      prefs.remove(openAqUserKey),
    ]);
    print(
        '[SettingsService clearUserSettings] <==== Finished removing keys for user $userId.');
  }
}