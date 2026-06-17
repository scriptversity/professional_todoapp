// lib/db.dart
import 'package:postgres/postgres.dart' as pg;

class Database {
  late pg.Connection connection;

  Future<void> connect() async {
    try {
    connection = await pg.Connection.open(
      pg.Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'professional_todo',
        username: 'postgres',
        password: 'password',
      ),
      settings: pg.ConnectionSettings(sslMode: pg.SslMode.disable),
    );
      print('✅ Connected to Postgres');
    } catch (e) {
      print('❌ Failed to connect to database: $e');
      // Handle error or retry connection
    }
  }
}
