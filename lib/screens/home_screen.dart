import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Énergie'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
              Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Système de Sous-Comptage',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  context,
                  'Maison 1',
                  Icons.home,
                  'house1',
                ),
                const SizedBox(height: 20),
                _buildButton(
                  context,
                  'Maison 2',
                  Icons.house,
                  'house2',
                ),
                const SizedBox(height: 20),
                _buildButton(
                  context,
                  'Propriétaire',
                  Icons.admin_panel_settings,
                  'proprietaire',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, IconData icon, String userType) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(userType: userType),
            ),
          );
        },
      ),
    );
  }
}
