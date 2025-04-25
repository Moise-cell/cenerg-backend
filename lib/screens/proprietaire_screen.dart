import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
// import '../services/database_service.dart';
import 'house_screen.dart';
import 'login_screen.dart';

class ProprietaireScreen extends StatefulWidget {
  const ProprietaireScreen({Key? key}) : super(key: key);

  @override
  State<ProprietaireScreen> createState() => _ProprietaireScreenState();
}


class _ProprietaireScreenState extends State<ProprietaireScreen> {
  List<Map<String, dynamic>> _houses = [];
  List<User> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHouses();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://cenerg-backend.onrender.com/api/users'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _users = data.map((json) => User.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updatePhone(String username, String phone) async {
    final response = await http.put(
      Uri.parse('https://cenerg-backend.onrender.com/api/users/$username/phone'),
      headers: {'Content-Type': 'application/json', 'X-User-Type': 'proprietaire'},
      body: json.encode({'phone': phone}),
    );
    if (response.statusCode == 200) {
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numéro de $username mis à jour')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification')), 
      );
    }
  }

  Future<void> _loadHouses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Appel API Flask pour récupérer la liste des maisons
      final response = await http.get(
        Uri.parse('https://cenerg-backend.onrender.com/api/houses'),
      );
      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Erreur lors de la récupération des maisons';
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> result = json.decode(response.body);
      if (mounted) {
        setState(() {
          _houses = result.map((row) => {
            'id': row['id'],
            'name': row['name'],
            'address': row['address'],
            'user_count': row['user_count'],
            'daily_energy': row['daily_energy'] ?? 0.0,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des maisons: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildUserList() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ListTile(
            title: Text('Utilisateurs et numéros'),
          ),
          ..._users.map((user) => ListTile(
                title: Text('${user.username} (${user.role})'),
                subtitle: Text(user.phone),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final controller = TextEditingController(text: user.phone);
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Modifier le numéro de ${user.username}'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Numéro'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result != user.phone) {
                      await _updatePhone(user.username, result);
                    }
                  },
                ),
              ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHouses,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHouses,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    _buildUserList(),
                    if (_houses.isEmpty)
                      const Center(child: Text('Aucune maison trouvée'))
                    else
                      ...[
                        const Divider(),
                        RefreshIndicator(
                          onRefresh: _loadHouses,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _houses.length,
                            itemBuilder: (context, index) {
                              final house = _houses[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(house['name']),
                                  subtitle: Text(house['address']),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${house['daily_energy'].toStringAsFixed(1)} kWh',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        '${house['user_count']} utilisateurs',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HouseScreen(
                                          houseId: house['id'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ]
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implémenter l'ajout d'une nouvelle maison
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
