// lib/handlers.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart' as pg;  // ✅ add this
import 'db.dart';

class Handlers {
  final Database db;

  Handlers(this.db);

  Router get router {
    final router = Router();

    // Create a sub-router for /api/v1
    final api = Router();

    // POST /register
    router.post('/register', (Request request) async {
      final body = await request.readAsString();
      final data = Uri.splitQueryString(body);

      final name = data['name'];
      final email = data['email'];
      final password = data['password'];

      if (name == null || email == null || password == null) {
        return Response(400, body: 'Missing name, email, or password');
      }

      // Hash the password
      final hash = BCrypt.hashpw(password, BCrypt.gensalt());

      try {
        final result = await db.connection.execute(
          pg.Sql.named(
            'INSERT INTO users (name, email, password_hash) VALUES (@name, @email, @password_hash) RETURNING id'
          ),
          parameters: {
            'name': name,
            'email': email,
            'password_hash': hash,
          },
        );

        final userId = result.first[0].toString();
        return Response.ok('User registered successfully. ID: $userId');
      } catch (e) {
        return Response(500, body: 'Error registering user: $e');
      }
    });

    // POST /login
    router.post('/login', (Request request) async {
      final body = await request.readAsString();
      // final data = Uri.splitQueryString(body);
      // Use this if your React/Axios frontend sends JSON data
      final data = jsonDecode(body) as Map<String, dynamic>; // JSON → Map better than URI

      final email = data['email'];
      final password = data['password'];

      if (email == null || password == null) {
        return Response(400, body: 'Missing email or password');
      }

      final result = await db.connection.execute(
        pg.Sql.named('SELECT id, password_hash FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return Response(401, body: 'Invalid credentials');
      }

      final row = result.first;
      final userId = row[0].toString();   // UUID → String
      final hash = row[1] as String;      // Cast to String

      final isValid = BCrypt.checkpw(password, hash);

      if (!isValid) {
        return Response(401, body: 'Invalid credentials');
      }

      return Response.ok('Login successful. User ID: $userId');
    });

    // Register the sub-router for /api/v1
    router.mount('/api/v1/', api);
    
    return router;
  }
}
