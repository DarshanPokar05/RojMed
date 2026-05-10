// lib/data/local/dao/entries_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'entries_dao.g.dart';

@DriftAccessor(tables: [DailyEntries])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  // ── Queries ──────────────────────────────────────────────

  /// Get a single entry by date (returns null if not found)
  Future<DailyEntry?> getEntryByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay   = startOfDay.add(const Duration(days: 1));
    return (select(dailyEntries)
      ..where((t) =>
          t.entryDate.isBiggerOrEqualValue(startOfDay) &
          t.entryDate.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  /// Get all entries for a given month (for calendar + summary)
  Future<List<DailyEntry>> getEntriesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 1);
    return (select(dailyEntries)
      ..where((t) =>
          t.entryDate.isBiggerOrEqualValue(start) &
          t.entryDate.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.entryDate)]))
        .get();
  }

  /// Get all entries (for full history)
  Future<List<DailyEntry>> getAllEntries() {
    return (select(dailyEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .get();
  }

  /// Get yesterday's entry to auto-fill opening balance
  Future<DailyEntry?> getYesterdayEntry(DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return getEntryByDate(yesterday);
  }

  /// Get all unsynced entries
  Future<List<DailyEntry>> getUnsyncedEntries() {
    return (select(dailyEntries)
      ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  /// Watch today's entry as a stream (live updates)
  Stream<DailyEntry?> watchEntryByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay   = startOfDay.add(const Duration(days: 1));
    return (select(dailyEntries)
      ..where((t) =>
          t.entryDate.isBiggerOrEqualValue(startOfDay) &
          t.entryDate.isSmallerThanValue(endOfDay)))
        .watchSingleOrNull();
  }

  /// Watch all entries for a month (live updates for calendar)
  Stream<List<DailyEntry>> watchEntriesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 1);
    return (select(dailyEntries)
      ..where((t) =>
          t.entryDate.isBiggerOrEqualValue(start) &
          t.entryDate.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.entryDate)]))
        .watch();
  }

  // ── Mutations ─────────────────────────────────────────────

  /// Insert or update a daily entry (upsert by date)
  Future<String> upsertEntry(DailyEntriesCompanion entry) async {
    await into(dailyEntries).insertOnConflictUpdate(entry);
    // Return the id from companion or generate one
    return entry.id.value;
  }

  /// Mark an entry as synced
  Future<void> markSynced(String entryId, DateTime syncedAt) {
    return (update(dailyEntries)
      ..where((t) => t.id.equals(entryId)))
        .write(DailyEntriesCompanion(
          isSynced: const Value(true),
          syncedAt: Value(syncedAt),
        ));
  }

  /// Delete an entry by id
  Future<void> deleteEntry(String entryId) {
    return (delete(dailyEntries)
      ..where((t) => t.id.equals(entryId)))
        .go();
  }

  /// Delete all entries (used for reset / re-sync)
  Future<void> deleteAll() => delete(dailyEntries).go();
}
