import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database/database_factory_helper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();
  runApp(MacroMateApp(auth: AuthController()));
}
