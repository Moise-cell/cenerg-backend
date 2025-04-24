import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import '../services/database_service.dart';
import 'house_screen.dart';
import 'proprietaire_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final response = await http.post(
      Uri.parse('https://cenerg-backend.onrender.com/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      setState(() {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        _isLoading = false;
      });
      return;
    }

    final responseData = json.decode(response.body);
    if (responseData['success'] == true) {
      final user = responseData['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user['username']);
      await prefs.setString('access_level', user['user_type']);

      if (!mounted) return;

      if (user['user_type'] == 'proprietaire') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProprietaireScreen(),
          ),
        );
      } else {
        // Navigation automatique vers HouseScreen pour maison1/maison2
        final houseId = user['house_id'];
        if (houseId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HouseScreen(houseId: houseId),
            ),
          );
        } else {
          setState(() {
            _errorMessage = "Aucune maison associée à cet utilisateur.";
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom d\'utilisateur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
