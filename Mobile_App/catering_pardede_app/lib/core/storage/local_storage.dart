import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _tokenKey = 'auth_token';
  static const _viewedKey = 'recently_viewed';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> addRecentlyViewed(String menuJson) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_viewedKey) ?? [];
    
    // Remove if already exists to move it to the front
    history.removeWhere((item) => item == menuJson);
    history.insert(0, menuJson);
    
    // Limit to 5 items
    if (history.length > 5) {
      history = history.sublist(0, 5);
    }
    
    await prefs.setStringList(_viewedKey, history);
  }

  static Future<List<String>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_viewedKey) ?? [];
  }
}
