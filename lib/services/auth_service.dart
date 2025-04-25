import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'cache_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static User? _currentUser;

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    _currentUser = User.fromJson(jsonDecode(userJson));
    return _currentUser;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<User> login(String username, String password) async {
    try {
      final response = await ApiService.postData('auth/login', {
        'username': username,
        'password': password,
      });

      if (response['token'] != null) {
        await setToken(response['token']);
        
        _currentUser = User.fromJson(response['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        
        return _currentUser!;
      }

      throw Exception('Échec de connexion: Token manquant');
    } catch (e) {
      throw Exception('Échec de connexion: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await CacheService.clearAllCache();
    _currentUser = null;
  }

  static Future<String> getNavigationRoute() async {
    final user = await getCurrentUser();
    if (user == null) return '/login';
    
    if (user.isOwner) {
      return '/owner';
    } else if (user.isHouse1) {
      return '/house1/${user.houseId}';
    } else if (user.isHouse2) {
      return '/house2/${user.houseId}';
    }
    
    throw Exception('Type d\'utilisateur non reconnu');
  }

  static Future<bool> hasPermission(String action) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    switch (action) {
      case 'view_all_houses':
        return user.isOwner;
      case 'manage_users':
        return user.isOwner;
      case 'view_house_details':
        return user.isOwner || user.isHouse;
      case 'modify_house_settings':
        return user.isOwner;
      case 'view_consumption':
        return true; // Tous les utilisateurs peuvent voir la consommation
      default:
        return false;
    }
  }
}
