import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorage {
  static const _tokenKey = 'auth_token';
  static const _viewedKey = 'recently_viewed';

  static String _chatCacheKey(int orderId) => 'chat_cache_order_$orderId';
  static String _chatPendingKey(int orderId) => 'chat_pending_send_order_$orderId';

  static Future<void> saveChatCache(int orderId, List<Map<String, dynamic>> messagesJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatCacheKey(orderId), jsonEncode(messagesJson));
  }

  static Future<List<Map<String, dynamic>>> getChatCache(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_chatCacheKey(orderId));
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePendingMessages(int orderId, List<Map<String, dynamic>> pendingJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatPendingKey(orderId), jsonEncode(pendingJson));
  }

  static Future<List<Map<String, dynamic>>> getPendingMessages(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_chatPendingKey(orderId));
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

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
    
    // Hapus jika sudah ada untuk memindahkannya ke antrean depan
    history.removeWhere((item) => item == menuJson);
    history.insert(0, menuJson);
    
    // Batasi hingga 5 item
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
