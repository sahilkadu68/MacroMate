import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initializes the appropriate SQLite databaseFactory based on the running platform.
/// On Android/iOS: Uses default native sqflite.
/// On Web: Uses sqflite_common_ffi_web (IndexedDB backed).
/// On Desktop / Unit tests: Uses sqflite_common_ffi (C SQLite3 FFI).
void initDatabaseFactory() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
