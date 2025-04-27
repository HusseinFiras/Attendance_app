import 'package:flutter/material.dart';
import '../../data/database/database.dart';

class DatabaseProvider extends ChangeNotifier {
  late final AppDatabase database;

  DatabaseProvider() {
    database = AppDatabase();
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }
} 