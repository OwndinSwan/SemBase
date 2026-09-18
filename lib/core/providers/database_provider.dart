import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Single source of truth for local Drift SQLite DB
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

/// Watches active academic profile
final activeProfileStreamProvider = StreamProvider<AcademicProfile?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveProfile();
});
