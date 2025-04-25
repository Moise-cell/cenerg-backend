import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/services/database_service.dart';

Future<void> main() async {
  // Charger les variables d'environnement
  await dotenv.load();

  // Se connecter à la base de données
  final db = DatabaseService();
  try {
    await db.connect(
      host: dotenv.env['DB_HOST']!,
      port: int.parse(dotenv.env['DB_PORT']!),
      database: dotenv.env['DB_NAME']!,
      username: dotenv.env['DB_USER']!,
      password: dotenv.env['DB_PASSWORD']!,
    );

    print('Connexion à la base de données réussie');
    
    // Créer les tables
    await db._connection.query('''
      CREATE EXTENSION IF NOT EXISTS pgcrypto;
      
      CREATE TABLE IF NOT EXISTS houses (
        id SERIAL PRIMARY KEY,
        house_number INTEGER NOT NULL UNIQUE,
        remaining_energy DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
        phone_number VARCHAR(15),
        last_update TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS energy_recharges (
        id SERIAL PRIMARY KEY,
        house_id INTEGER REFERENCES houses(id),
        amount DECIMAL(10, 2) NOT NULL,
        recharge_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('proprietaire', 'house')),
        house_id INTEGER REFERENCES houses(id)
      );
    ''');

    // Insérer les données initiales
    await db._connection.query('''
      INSERT INTO houses (house_number, remaining_energy, phone_number)
      VALUES 
        (1, 0.0, '+33600000001'),
        (2, 0.0, '+33600000002')
      ON CONFLICT (house_number) DO NOTHING;

      INSERT INTO users (username, password_hash, user_type)
      VALUES ('admin', crypt('admin123', gen_salt('bf')), 'proprietaire')
      ON CONFLICT (username) DO NOTHING;
    ''');

    print('Base de données initialisée avec succès');
  } catch (e) {
    print('Erreur lors de l\'initialisation de la base de données: $e');
  } finally {
    await db.close();
  }
}
