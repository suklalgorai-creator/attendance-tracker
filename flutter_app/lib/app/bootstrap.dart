import 'package:flutter/material.dart';
import '../core/services/database_service.dart';

/// Prepares bindings, storage, and platform configurations before runApp.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
}
