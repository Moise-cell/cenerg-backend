import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

class ESP32Service {
  static final ESP32Service _instance = ESP32Service._internal();
  final Connectivity _connectivity = Connectivity();
  static const int _timeout = 5; // Timeout en secondes
  static const String _baseUrl = 'https://cenerg-backend.onrender.com'; // URL du backend Flask Render
  
  factory ESP32Service() {
    return _instance;
  }

  ESP32Service._internal() {
    // Initialiser la surveillance de la connectivité
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      // Synchroniser les données en attente quand la connexion est rétablie
      _syncPendingData();
    }
  }

  // Vérifier la connectivité avant d'effectuer des opérations réseau
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi || 
           connectivityResult == ConnectivityResult.mobile;
  }

  // Synchroniser les données en attente
  Future<void> _syncPendingData() async {
    // TODO: Implémenter la synchronisation des données en attente
  }

  // Obtenir l'énergie restante pour une maison
  Future<double> getRemainingEnergy(int houseNumber) async {
    if (!await _checkConnectivity()) {
      throw Exception('Pas de connexion Internet');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/house/$houseNumber/energy'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['remaining_energy'].toDouble();
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'énergie: $e');
      rethrow;
    }
  }

  // Recharger l'énergie d'une maison
  Future<Map<String, dynamic>> rechargeEnergy(int houseNumber, double amount) async {
    if (!await _checkConnectivity()) {
      throw Exception('Pas de connexion Internet');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/house/$houseNumber/energy/recharge'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la recharge');
      }
    } catch (e) {
      print('Erreur lors de la recharge: $e');
      rethrow;
    }
  }

  // Récupérer les dernières données pour un appareil spécifique
  Future<List<Map<String, dynamic>>> getDeviceData(String deviceId, {int limit = 100}) async {
    try {
      return await _db.getEsp32Data(deviceId, limit: limit);
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques pour un appareil
  Future<Map<String, dynamic>> getDeviceStats(String deviceId) async {
    try {
      final data = await _db.getEsp32Data(deviceId, limit: 24); // Dernières 24 mesures
      
      if (data.isEmpty) {
        return {
          'average_temperature': 0.0,
          'average_humidity': 0.0,
          'min_temperature': 0.0,
          'max_temperature': 0.0,
          'min_humidity': 0.0,
          'max_humidity': 0.0,
        };
      }

      final temperatures = data.map((e) => e['temperature'] as double).toList();
      final humidities = data.map((e) => e['humidity'] as double).toList();

      return {
        'average_temperature': temperatures.reduce((a, b) => a + b) / temperatures.length,
        'average_humidity': humidities.reduce((a, b) => a + b) / humidities.length,
        'min_temperature': temperatures.reduce((a, b) => a < b ? a : b),
        'max_temperature': temperatures.reduce((a, b) => a > b ? a : b),
        'min_humidity': humidities.reduce((a, b) => a < b ? a : b),
        'max_humidity': humidities.reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      rethrow;
    }
  }

  // Vérification de la connexion à l'ESP32
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(Duration(seconds: _timeout));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupération des données de mesure
  static Future<Map<String, dynamic>> getMeasurements(int houseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/measurements/$houseId'),
      ).timeout(Duration(seconds: _timeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Sauvegarder dans la base de données
        throw Exception('Connexion directe désactivée. Utilisez l\'API Flask.'); // await DatabaseService.query(
          '''
          INSERT INTO energy_measurements 
          (house_id, voltage, current1, current2, energy1, energy2)
          VALUES (@houseId, @voltage, @current1, @current2, @energy1, @energy2)
          ''',
          substitutionValues: {
            'houseId': houseId,
            'voltage': data['voltage'],
            'current1': data['current1'],
            'current2': data['current2'],
            'energy1': data['energy1'],
            'energy2': data['energy2'],
          },
        );

        return data;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion à l\'ESP32: $e');
    }
  }

  // Contrôle des relais
  static Future<bool> setRelay(int houseId, int relayNumber, bool state) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/relay/$houseId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'relay': relayNumber,
          'state': state,
        }),
      ).timeout(Duration(seconds: _timeout));

      if (response.statusCode == 200) {
        // Enregistrer l'action dans la base de données
        throw Exception('Connexion directe désactivée. Utilisez l\'API Flask.'); // await DatabaseService.query(
          '''
          INSERT INTO relay_actions 
          (house_id, relay_number, action_state, timestamp)
          VALUES (@houseId, @relay, @state, CURRENT_TIMESTAMP)
          ''',
          substitutionValues: {
            'houseId': houseId,
            'relay': relayNumber,
            'state': state,
          },
        );
        return true;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion à l\'ESP32: $e');
    }
  }

  // Récupération de l'historique des mesures
  static Future<List<Map<String, dynamic>>> getMeasurementHistory(
    int houseId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = throw Exception('Connexion directe désactivée. Utilisez l\'API Flask.'); // await DatabaseService.query(
        '''
        SELECT voltage, current1, current2, energy1, energy2, timestamp
        FROM energy_measurements
        WHERE house_id = @houseId
        ${startDate != null ? 'AND timestamp >= @startDate' : ''}
        ${endDate != null ? 'AND timestamp <= @endDate' : ''}
        ORDER BY timestamp DESC
        LIMIT 100
        ''',
        substitutionValues: {
          'houseId': houseId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      return result.map((row) => {
        'voltage': row[0] as double,
        'current1': row[1] as double,
        'current2': row[2] as double,
        'energy1': row[3] as double,
        'energy2': row[4] as double,
        'timestamp': row[5] as DateTime,
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }
}
