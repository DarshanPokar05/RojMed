// lib/data/local/dao/items_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [EntryItems])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  // ── Queries ──────────────────────────────────────────────

  /// Get all items for an entry
  Future<List<EntryItem>> getItemsForEntry(String entryId) {
    return (select(entryItems)
      ..where((t) => t.dailyEntryId.equals(entryId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Get shop items only for an entry
  Future<List<EntryItem>> getShopItems(String entryId) {
    return (select(entryItems)
      ..where((t) =>
          t.dailyEntryId.equals(entryId) &
          t.type.equals('shop'))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Get personal items only for an entry
  Future<List<EntryItem>> getPersonalItems(String entryId) {
    return (select(entryItems)
      ..where((t) =>
          t.dailyEntryId.equals(entryId) &
          t.type.equals('personal'))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Watch items for an entry as stream
  Stream<List<EntryItem>> watchItemsForEntry(String entryId) {
    return (select(entryItems)
      ..where((t) => t.dailyEntryId.equals(entryId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Get all unsynced items
  Future<List<EntryItem>> getUnsyncedItems() {
    return (select(entryItems)
      ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  // ── Mutations ─────────────────────────────────────────────

  /// Insert a new item
  Future<void> insertItem(EntryItemsCompanion item) {
    return into(entryItems).insert(item);
  }

  /// Insert multiple items at once
  Future<void> insertItems(List<EntryItemsCompanion> items) async {
    await batch((b) => b.insertAll(entryItems, items));
  }

  /// Update a single item
  Future<void> updateItem(EntryItemsCompanion item) {
    return (update(entryItems)
      ..where((t) => t.id.equals(item.id.value)))
        .write(item);
  }

  /// Delete a single item
  Future<void> deleteItem(String itemId) {
    return (delete(entryItems)
      ..where((t) => t.id.equals(itemId)))
        .go();
  }

  /// Delete all items for an entry (before re-inserting on save)
  Future<void> deleteItemsForEntry(String entryId) {
    return (delete(entryItems)
      ..where((t) => t.dailyEntryId.equals(entryId)))
        .go();
  }

  /// Mark all items for an entry as synced
  Future<void> markItemsSynced(String entryId) {
    return (update(entryItems)
      ..where((t) => t.dailyEntryId.equals(entryId)))
        .write(const EntryItemsCompanion(
          isSynced: Value(true),
        ));
  }
}
