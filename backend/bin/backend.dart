// bin/backend.dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import '../lib/db.dart';
import '../lib/handlers.dart';

void main() async {
  final db = Database();
  await db.connect();

  final handlers = Handlers(db);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(handlers.router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('🚀 Server running on http://${server.address.host}:${server.port}');
}
