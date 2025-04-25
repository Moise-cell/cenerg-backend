import 'api_service.dart';
import 'auth_service.dart';

class EnergyService {
  static Future<Map<String, dynamic>> getEnergyData(String houseId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    return await ApiService.getData('energy/$houseId');
  }

  static Future<Map<String, dynamic>> getEnergyHistory(
    String houseId, {
    String? startDate,
    String? endDate,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    String endpoint = 'energy/$houseId/history';
    if (startDate != null && endDate != null) {
      endpoint += '?start=$startDate&end=$endDate';
    }

    return await ApiService.getData(endpoint);
  }

  static Future<Map<String, dynamic>> updateEnergySettings(
    String houseId,
    Map<String, dynamic> settings,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    return await ApiService.putData(
      'energy/$houseId/settings',
      settings,
    );
  }

  static Future<Map<String, dynamic>> getEnergyStats(String houseId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    return await ApiService.getData('energy/$houseId/stats');
  }

  static Future<Map<String, dynamic>> setEnergyAlert(
    String houseId,
    Map<String, dynamic> alertSettings,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    return await ApiService.postData(
      'energy/$houseId/alerts',
      alertSettings,
    );
  }

  static Future<List<Map<String, dynamic>>> getEnergyAlerts(String houseId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.getData('energy/$houseId/alerts');
    return List<Map<String, dynamic>>.from(response['alerts'] ?? []);
  }
}
