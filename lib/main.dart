import 'package:flutter/material.dart';
import 'app.dart';
import 'data/database/database_factory_helper.dart';
import 'data/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cross-platform SQLite database factory (Android native, Web IndexedDB, Desktop FFI)
  initDatabaseFactory();

  // Pre-warm database and verify initial idempotent seed data
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  runApp(const MacroMateApp());
}
