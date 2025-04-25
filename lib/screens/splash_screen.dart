import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/platform_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Vérifier la compatibilité du dispositif
      await PlatformService.checkDeviceCompatibility();

      // 2. Vérifier les permissions
      final hasPermissions = await PlatformService.checkAndRequestPermissions();
      if (!hasPermissions) {
        if (mounted) {
          _showError('Permissions nécessaires non accordées');
        }
        return;
      }

      // 3. Vérifier la connexion au serveur
      final serverAvailable = await ApiService.checkApiAvailability();
      if (!serverAvailable) {
        if (mounted) {
          _showError('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
        }
        return;
      }

      // 4. Vérifier l'authentification
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // 5. Obtenir la route de navigation selon le type d'utilisateur
      final route = await AuthService.getNavigationRoute();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showError(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 150),
                const SizedBox(height: 24),
                const CupertinoActivityIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Chargement...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 150),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Chargement...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
