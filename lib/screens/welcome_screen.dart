import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/wifi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isCheckingConnection = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkPreviousLogin();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    _isConnected = await WiFiService.checkServerAvailability();
    if (mounted) {
      setState(() => _isCheckingConnection = false);
    }
  }

  Future<void> _checkPreviousLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final accessLevel = prefs.getString('access_level');

    if (userId != null && accessLevel != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou Icône
                Icon(
                  Icons.energy_savings_leaf,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                // Titre
                const Text(
                  'CenErg',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Sous-titre
                const Text(
                  'Gestion Intelligente de l\'Énergie',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                // Indicateur de connexion
                if (_isCheckingConnection)
                  const CircularProgressIndicator(color: Colors.white)
                else if (!_isConnected)
                  Column(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pas de connexion au serveur',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _checkConnection,
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(
                    Icons.wifi,
                    color: Colors.green,
                    size: 48,
                  ),
                const SizedBox(height: 48),
                // Bouton de connexion
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Commencer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
