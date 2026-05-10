// lib/core/sync_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/local/tables.dart';
import '../data/remote/supabase_service.dart';
import '../data/models/daily_entry_model.dart';
import '../data/models/entry_item.dart';

enum SyncStatus { idle, syncing, synced, error, offline }

class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  SyncStatus _status   = SyncStatus.idle;
  DateTime?  _lastSync;
  String?    _errorMsg;

  SyncStatus get status   => _status;
  DateTime?  get lastSync => _lastSync;
  String?    get errorMsg => _errorMsg;
  bool get isSyncing      => _status == SyncStatus.syncing;
  bool get isOnline       => _status != SyncStatus.offline;

  final _supabase = SupabaseService.instance;
  final _db       = database;

  // ── Public API ────────────────────────────────────────────

  /// Call on app startup and network restore
  Future<void> syncAll() async {
    if (!await _isOnline()) {
      _setStatus(SyncStatus.offline);
      return;
    }
    _setStatus(SyncStatus.syncing);
    try {
      await _pushUnsynced();
      await _pullFromCloud();
      _lastSync = DateTime.now();
      _setStatus(SyncStatus.synced);
    } catch (e) {
      _errorMsg = e.toString();
      _setStatus(SyncStatus.error);
      debugPrint('[SyncService] Error: $e');
    }
  }

  /// Call after every local save
  Future<void> syncEntry(String entryId) async {
    if (!await _isOnline()) return;
    try {
      final entry = await _getLocalEntryModel(entryId);
      if (entry == null) return;
      await _supabase.upsertEntry(entry);
      final items = await _getLocalItems(entryId);
      await _supabase.deleteItemsForEntry(entryId);
      await _supabase.upsertItems(items);
      final now = DateTime.now();
      await _db.entriesDao.markSynced(entryId, now);
      _lastSync = now;
      _setStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('[SyncService] syncEntry error: $e');
    }
  }

  /// Listen to connectivity and auto-sync
  void startListening() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet) syncAll();
    });
  }

  // ── Private ───────────────────────────────────────────────

  Future<void> _pushUnsynced() async {
    final unsynced = await _db.entriesDao.getUnsyncedEntries();
    for (final entry in unsynced) {
      final model = await _buildEntryModel(entry);
      await _supabase.upsertEntry(model);
      final items = await _getLocalItems(entry.id);
      await _supabase.deleteItemsForEntry(entry.id);
      await _supabase.upsertItems(items);
      await _db.entriesDao.markSynced(entry.id, DateTime.now());
    }
  }

  Future<void> _pullFromCloud() async {
    final remoteEntries = await _supabase.fetchAllEntries();
    for (final remote in remoteEntries) {
      // Upsert entry locally
      await _db.entriesDao.upsertEntry(DailyEntriesCompanion(
        id:              Value(remote.id),
        entryDate:       Value(remote.entryDate),
        openingBalance:  Value(remote.openingBalance),
        dailyCollection: Value(remote.dailyCollection),
        shopTotal:       Value(remote.shopTotal),
        personalTotal:   Value(remote.personalTotal),
        closingBalance:  Value(remote.closingBalance),
        cornerNumber:    Value(remote.cornerNumber),
        notes:           Value(remote.notes),
        isSynced:        const Value(true),
        syncedAt:        Value(remote.syncedAt),
      ));

      // Fetch and upsert items
      final remoteItems = await _supabase.fetchItemsForEntry(remote.id);
      await _db.itemsDao.deleteItemsForEntry(remote.id);
      for (int i = 0; i < remoteItems.length; i++) {
        final item = remoteItems[i];
        await _db.itemsDao.insertItem(EntryItemsCompanion(
          id:           Value(item.id),
          dailyEntryId: Value(item.dailyEntryId),
          type:         Value(item.type),
          label:        Value(item.label),
          amount:       Value(item.amount),
          sortOrder:    Value(item.sortOrder),
          isSynced:     const Value(true),
        ));
      }
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<DailyEntryModel?> _getLocalEntryModel(String entryId) async {
    final entries = await _db.entriesDao.getAllEntries();
    final match = entries.where((e) => e.id == entryId).toList();
    if (match.isEmpty) return null;
    return _buildEntryModel(match.first);
  }

  Future<DailyEntryModel> _buildEntryModel(DailyEntry entry) async {
    return DailyEntryModel(
      id:              entry.id,
      entryDate:       entry.entryDate,
      openingBalance:  entry.openingBalance,
      dailyCollection: entry.dailyCollection,
      shopTotal:       entry.shopTotal,
      personalTotal:   entry.personalTotal,
      closingBalance:  entry.closingBalance,
      cornerNumber:    entry.cornerNumber,
      notes:           entry.notes,
      isSynced:        entry.isSynced,
      syncedAt:        entry.syncedAt,
      createdAt:       entry.createdAt,
    );
  }

  Future<List<EntryItemModel>> _getLocalItems(String entryId) async {
    final items = await _db.itemsDao.getItemsForEntry(entryId);
    return items.map((i) => EntryItemModel(
      id:           i.id,
      dailyEntryId: i.dailyEntryId,
      type:         i.type,
      label:        i.label,
      amount:       i.amount,
      sortOrder:    i.sortOrder,
      isSynced:     i.isSynced,
      createdAt:    i.createdAt,
    )).toList();
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }
}
