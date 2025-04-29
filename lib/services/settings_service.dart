// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // --- Clés SharedPreferences ---
  static const String _nytApiKey = 'nyt_api_key';
  static const String _openAqApiKey = 'openaq_api_key';

  // --- NYT API Key Methods ---
  static Future<String?> getNytApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_nytApiKey);
    // print('[DEBUG SettingsService] Retrieved NYT key: ${key ?? "null"}');
    return key;
  }
  static Future<void> saveNytApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // print('[DEBUG SettingsService] Saving NYT key: $key');
    await prefs.setString(_nytApiKey, key);
  }
  static Future<void> clearNytApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    // print('[DEBUG SettingsService] Clearing NYT key.');
    await prefs.remove(_nytApiKey);
  }

  // --- OpenAQ API Key Methods ---
  static Future<String?> getOpenAqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_openAqApiKey);
    print('[DEBUG SettingsService] Retrieved OpenAQ key: ${key ?? "null"}');
    return key;
  }

  static Future<void> saveOpenAqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    print('[DEBUG SettingsService] Saving OpenAQ key: $key');
    await prefs.setString(_openAqApiKey, key);
  }

  static Future<void> clearOpenAqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    print('[DEBUG SettingsService] Clearing OpenAQ key.');
    await prefs.remove(_openAqApiKey);
  }
}