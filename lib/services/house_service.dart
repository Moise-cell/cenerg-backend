import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class House {
  final String id;
  final String name;
  final String address;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime lastUpdate;

  House({
    required this.id,
    required this.name,
    required this.address,
    this.isActive = true,
    required this.settings,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      settings: json['settings'] ?? {},
      lastUpdate: json['last_update'] != null 
        ? DateTime.parse(json['last_update'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'is_active': isActive,
      'settings': settings,
      'last_update': lastUpdate.toIso8601String(),
    };
  }
}

class HouseService {
  static const String _cacheKey = 'houses_cache';
  static Map<String, House> _housesCache = {};

  static Future<List<House>> getAllHouses() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('Non authentifié');

    if (!user.isOwner) {
      // Pour les utilisateurs maison, retourner uniquement leur maison
      if (user.houseId == null) throw Exception('ID de maison manquant');
      final house = await getHouseById(user.houseId!);
      return [house];
    }

    try {
      final response = await ApiService.getData('houses');
      final List<House> houses = (response['houses'] as List)
          .map((h) => House.fromJson(h))
          .toList();

      // Mise en cache
      _housesCache = {for (var h in houses) h.id: h};
      _saveToCache();

      return houses;
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache
      return _loadFromCache();
    }
  }

  static Future<House> getHouseById(String houseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('Non authentifié');

    // Vérifier les permissions
    if (!user.isOwner && user.houseId != houseId) {
      throw Exception('Accès non autorisé à cette maison');
    }

    try {
      if (_housesCache.containsKey(houseId)) {
        return _housesCache[houseId]!;
      }

      final response = await ApiService.getData('houses/$houseId');
      final house = House.fromJson(response);
      
      // Mise en cache
      _housesCache[houseId] = house;
      _saveToCache();

      return house;
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache
      final houses = await _loadFromCache();
      final house = houses.firstWhere(
        (h) => h.id == houseId,
        orElse: () => throw Exception('Maison non trouvée'),
      );
      return house;
    }
  }

  static Future<void> updateHouseSettings(String houseId, Map<String, dynamic> settings) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('Non authentifié');

    // Seul le propriétaire peut modifier les paramètres
    if (!user.isOwner) {
      throw Exception('Permission refusée');
    }

    try {
      final response = await ApiService.putData(
        'houses/$houseId/settings',
        settings,
      );

      final updatedHouse = House.fromJson(response);
      _housesCache[houseId] = updatedHouse;
      _saveToCache();
    } catch (e) {
      throw Exception('Échec de la mise à jour des paramètres: $e');
    }
  }

  static Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final housesJson = _housesCache.values
        .map((h) => h.toJson())
        .toList();
    await prefs.setString(_cacheKey, jsonEncode(housesJson));
  }

  static Future<List<House>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return [];

    try {
      final List<dynamic> housesJson = jsonDecode(cached);
      final houses = housesJson
          .map((h) => House.fromJson(h))
          .toList();
      
      _housesCache = {for (var h in houses) h.id: h};
      return houses;
    } catch (e) {
      return [];
    }
  }
}
