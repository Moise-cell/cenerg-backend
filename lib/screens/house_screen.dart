import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/wifi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/user.dart';

class HouseScreen extends StatefulWidget {
  final int houseId;

  const HouseScreen({Key? key, required this.houseId}) : super(key: key);

  @override
  _HouseScreenState createState() => _HouseScreenState();
}


class _HouseScreenState extends State<HouseScreen> {
  double _energy = 0.0;
  double _voltage = 0.0;
  double _current1 = 0.0;
  double _current2 = 0.0;
  Timer? _updateTimer;
  bool _isConnected = false;
  String _phone = '';
  String _username = '';
  String _role = '';
  String _proprietairePhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkConnection();
    _loadEnergy();
    _startRealTimeUpdates();
  }

  Future<void> _loadUserInfo() async {
    // À adapter selon ton système de session/auth (SharedPreferences ou autre)
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';
    _role = prefs.getString('access_level') ?? '';
    if (_username.isEmpty) return;
    try {
      final response = await http.get(Uri.parse('https://cenerg-backend.onrender.com/api/users/$_username'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _phone = data['phone'] ?? '';
        });
      }
      // Charger le numéro du propriétaire
      final respProp = await http.get(Uri.parse('https://cenerg-backend.onrender.com/api/users/proprietaire'));
      if (respProp.statusCode == 200) {
        final dataProp = json.decode(respProp.body);
        setState(() {
          _proprietairePhone = dataProp['phone'] ?? '';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    _isConnected = await WiFiService.checkServerAvailability();
    if (mounted) setState(() {});
  }

  Future<void> _startRealTimeUpdates() async {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _checkConnection();
        if (_isConnected) {
          final data = await WiFiService.getData('energy/${widget.houseId}');
          if (mounted) {
            setState(() {
              _energy = data['energy']?.toDouble() ?? 0.0;
              _voltage = data['voltage']?.toDouble() ?? 0.0;
              _current1 = data['current1']?.toDouble() ?? 0.0;
              _current2 = data['current2']?.toDouble() ?? 0.0;
            });
          }
          // Sauvegarder les valeurs localement
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('${widget.houseId}_energy', _energy);
          await prefs.setDouble('${widget.houseId}_voltage', _voltage);
          await prefs.setDouble('${widget.houseId}_current1', _current1);
          await prefs.setDouble('${widget.houseId}_current2', _current2);
        }
      } catch (e) {
        print('Erreur lors de la mise à jour des données: $e');
      }
    });
  }

  Future<void> _loadEnergy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _energy = prefs.getDouble('${widget.houseId}_energy') ?? 0.0;
          _voltage = prefs.getDouble('${widget.houseId}_voltage') ?? 0.0;
          _current1 = prefs.getDouble('${widget.houseId}_current1') ?? 0.0;
          _current2 = prefs.getDouble('${widget.houseId}_current2') ?? 0.0;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPhone = _phone.isNotEmpty;
    final showProprietaire = _proprietairePhone.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Maison ${widget.houseId}'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.wifi,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showPhone)
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text('Votre numéro'),
                  subtitle: Text(_phone),
                ),
              ),
            if (showProprietaire)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('Numéro du propriétaire'),
                  subtitle: Text(_proprietairePhone),
                ),
              ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Énergie Disponible',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_energy.toStringAsFixed(2)} kWh',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.flash_on),
                      title: Text('Tension'),
                      trailing: Text('${_voltage.toStringAsFixed(1)} V'),
                    ),
                    ListTile(
                      leading: Icon(Icons.bolt),
                      title: Text('Courant 1'),
                      trailing: Text('${_current1.toStringAsFixed(2)} A'),
                    ),
                    ListTile(
                      leading: Icon(Icons.bolt),
                      title: Text('Courant 2'),
                      trailing: Text('${_current2.toStringAsFixed(2)} A'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
