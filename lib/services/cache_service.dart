import 'dart:convert';
import 'package:shared_preferences.dart';

class CacheService {
  static const Duration defaultCacheDuration = Duration(seconds: 60);
  
  static Future<void> setCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }

  static Future<dynamic> getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(key);
    
    if (cachedString == null) return null;
    
    final cached = jsonDecode(cachedString);
    final timestamp = DateTime.parse(cached['timestamp']);
    
    if (DateTime.now().difference(timestamp) > defaultCacheDuration) {
      await prefs.remove(key); // Cache expiré, on le supprime
      return null;
    }
    
    return cached['data'];
  }

  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
