import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/storage/local_database.dart';

/// App entry point with local database initialization.
/// SQLite database is initialized before runApp to ensure
/// local progress data is available immediately.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.initialize();
  runApp(const MeowApp());
}
