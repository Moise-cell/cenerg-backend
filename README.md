import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthenticationService {
bool _isLoggedIn = false;

bool get isLoggedIn => _isLoggedIn;

Future<void> signIn(String email, String password) async {
// Ici, vous ajouteriez votre logique d'authentification
// Par exemple, appeler une API pour vérifier les informations d'identification
// ...

    if (// vérification réussie) {
      _isLoggedIn = true;
      // Émettre un événement pour notifier les écouteurs que l'état a changé
    }
}

Future<void> signOut() async {
// Ici, vous ajouteriez votre logique de déconnexion
// ...
_isLoggedIn = false;
// Émettre un événement pour notifier les écouteurs que l'état a changé
}
}

class HomePage extends StatelessWidget {
@override
Widget build(BuildContext context) {
final authService = Provider.of<AuthenticationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Page d\'accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authService.isLoggedIn)
              Text('Vous êtes connecté !'),
            else
              Text('Veuillez vous connecter.'),
            // ... (autres éléments de la page d'accueil)
          ],
        ),
      ),
    );
}
}

class LoginPage extends StatefulWidget {
@override
_LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

@override
Widget build(BuildContext context) {
final authService = Provider.of<AuthenticationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  // Autres validations (format d'email, etc.)
                  return null;
                },
              ),
              // ... (champ de saisie pour le mot de passe)
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    authService.signIn(
                      _emailController.text,
                      _passwordController.text,
                    );
                  }
                },
                child: Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
}
}

void main() {
runApp(
ChangeNotifierProvider(
create: (context) => AuthenticationService(),
child: MaterialApp(
home: HomePage(),
),
),
);
}