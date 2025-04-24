import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? 'https://api.cenerg.com'; // À remplacer par votre URL d'API
  }

  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  static Future<bool> checkApiAvailability() async {
    final apiUrl = await getApiUrl();
    for (int i = 0; i < _maxRetries; i++) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/health'),
        ).timeout(_timeout);
        return response.statusCode == 200;
      } catch (e) {
        if (i == _maxRetries - 1) return false;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> getData(String endpoint) async {
    final apiUrl = await getApiUrl();
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$endpoint'),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> postData(String endpoint, Map<String, dynamic> data) async {
    final apiUrl = await getApiUrl();
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> putData(String endpoint, Map<String, dynamic> data) async {
    final apiUrl = await getApiUrl();
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteData(String endpoint) async {
    final apiUrl = await getApiUrl();
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$endpoint'),
      ).timeout(_timeout);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
