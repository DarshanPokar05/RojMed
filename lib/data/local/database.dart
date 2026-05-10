// lib/data/local/database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'dao/entries_dao.dart';
import 'dao/items_dao.dart';
import 'dao/settings_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [DailyEntries, EntryItems, AppSettings],
  daos:   [EntriesDao, ItemsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // future migrations go here
    },
  );
}

/// Singleton instance — use this throughout the app
AppDatabase? _dbInstance;
AppDatabase get database => _dbInstance ??= AppDatabase();

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'roj_med.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
