import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static PostgreSQLConnection? _connection;
  
  static Future<PostgreSQLConnection> get connection async {
    if (_connection == null || _connection!.isClosed) {
      await _connect();
    }
    return _connection!;
  }

  static Future<void> _connect() async {
    _connection = PostgreSQLConnection(
      dotenv.env['DB_HOST'] ?? '',
      int.parse(dotenv.env['DB_PORT'] ?? '5432'),
      dotenv.env['DB_NAME'] ?? '',
      username: dotenv.env['DB_USER'],
      password: dotenv.env['DB_PASSWORD'],
      useSSL: dotenv.env['DB_SSL']?.toLowerCase() == 'true',
    );

    try {
      await _connection!.open();
      print('Connexion à la base de données établie');
    } catch (e) {
      print('Erreur de connexion à la base de données: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      print('Connexion à la base de données fermée');
    }
  }

  // Méthodes utilitaires pour les requêtes courantes
  static Future<List<Map<String, dynamic>>> query(
    String sql, 
    [List<dynamic> params = const []]
  ) async {
    final conn = await connection;
    try {
      final results = await conn.mappedResultsQuery(sql, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      print('Erreur lors de la requête: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> queryOne(
    String sql, 
    [List<dynamic> params = const []]
  ) async {
    final results = await query(sql, params);
    return results.isEmpty ? null : results.first;
  }

  static Future<void> execute(
    String sql, 
    [List<dynamic> params = const []]
  ) async {
    final conn = await connection;
    try {
      await conn.execute(sql, substitutionValues: params);
    } catch (e) {
      print('Erreur lors de l\'exécution: $e');
      rethrow;
    }
  }

  static Future<T> transaction<T>(
    Future<T> Function(PostgreSQLConnection) operation
  ) async {
    final conn = await connection;
    return await conn.transaction((ctx) async {
      try {
        return await operation(ctx);
      } catch (e) {
        print('Erreur dans la transaction: $e');
        rethrow;
      }
    });
  }
}
