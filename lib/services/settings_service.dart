// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _nytApiKey = 'nyt_api_key'; // Clé pour SharedPreferences

  // Récupérer la clé API NYT
  static Future<String?> getNytApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nytApiKey);
  }

  // Sauvegarder la clé API NYT
  static Future<void> saveNytApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nytApiKey, key);
  }

  // Supprimer la clé API NYT
  static Future<void> clearNytApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nytApiKey);
  }
}