// lib/data/local/tables.dart

import 'package:drift/drift.dart';

/// Local SQLite table: daily_entries
class DailyEntries extends Table {
  TextColumn   get id               => text().clientDefault(() => _uuid())();
  DateTimeColumn get entryDate      => dateTime()();
  RealColumn   get openingBalance   => real().withDefault(const Constant(0.0))();
  RealColumn   get dailyCollection  => real().withDefault(const Constant(0.0))();
  RealColumn   get shopTotal        => real().withDefault(const Constant(0.0))();
  RealColumn   get personalTotal    => real().withDefault(const Constant(0.0))();
  RealColumn   get closingBalance   => real().withDefault(const Constant(0.0))();
  IntColumn    get cornerNumber     => integer().withDefault(const Constant(0))();
  TextColumn   get notes            => text().nullable()();
  BoolColumn   get isSynced         => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt       => dateTime().nullable()();
  DateTimeColumn get createdAt      => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{entryDate}];
}

/// Local SQLite table: entry_items
class EntryItems extends Table {
  TextColumn   get id             => text().clientDefault(() => _uuid())();
  TextColumn   get dailyEntryId  => text().references(DailyEntries, #id)();
  TextColumn   get type          => text()(); // 'shop' | 'personal'
  TextColumn   get label         => text()();
  RealColumn   get amount        => real().withDefault(const Constant(0.0))();
  IntColumn    get sortOrder     => integer().withDefault(const Constant(0))();
  BoolColumn   get isSynced      => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt   => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local SQLite table: app_settings (key-value store)
class AppSettings extends Table {
  TextColumn get key   => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}

/// Simple UUID v4 generator (no dependency needed for local IDs)
String _uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = now.hashCode ^ now.toString().hashCode;
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
    RegExp(r'[xy]'),
    (m) {
      final v = (rand >> (m.start * 4)) & 0xf;
      return (m.group(0) == 'x' ? v : (v & 0x3 | 0x8)).toRadixString(16);
    },
  );
}
