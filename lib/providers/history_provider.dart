// lib/providers/history_provider.dart

import 'package:flutter/foundation.dart';
import '../data/local/database.dart';
import '../data/local/tables.dart';
import '../data/models/daily_entry_model.dart';
import '../data/models/entry_item.dart';

class HistoryProvider extends ChangeNotifier {
  final _db = database;

  bool   _isLoading = false;
  String? _error;

  // Cache: date string → full model
  final Map<String, DailyEntryModel> _cache = {};
  // Dates with entries for calendar dots
  Set<DateTime> _datesWithEntries = {};

  bool            get isLoading        => _isLoading;
  String?         get error            => _error;
  Set<DateTime>   get datesWithEntries => _datesWithEntries;

  // ── Load month for calendar ───────────────────────────────

  Future<void> loadMonth(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final entries = await _db.entriesDao.getEntriesForMonth(year, month);
      _datesWithEntries = entries
          .map((e) => DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day))
          .toSet();

      // Cache lightweight versions
      for (final e in entries) {
        final key = _dateKey(e.entryDate);
        _cache[key] = _entryToModel(e);
      }
    } catch (err) {
      _error = err.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Get full entry for detail screen ─────────────────────

  Future<DailyEntryModel?> getEntryForDate(DateTime date) async {
    final key     = _dateKey(date);
    if (_cache.containsKey(key)) {
      // Load items if not yet loaded
      final cached = _cache[key]!;
      if (cached.shopItems.isEmpty && cached.personalItems.isEmpty) {
        return _loadWithItems(cached);
      }
      return cached;
    }

    final entry = await _db.entriesDao.getEntryByDate(date);
    if (entry == null) return null;
    return _loadWithItems(_entryToModel(entry));
  }

  Future<DailyEntryModel> _loadWithItems(DailyEntryModel model) async {
    final shopItems = await _db.itemsDao.getShopItems(model.id);
    final persItems = await _db.itemsDao.getPersonalItems(model.id);

    final full = model.copyWith(
      shopItems:     shopItems.map(_itemToModel).toList(),
      personalItems: persItems.map(_itemToModel).toList(),
    );
    _cache[_dateKey(model.entryDate)] = full;
    return full;
  }

  bool hasEntryForDate(DateTime date) =>
      _datesWithEntries.contains(DateTime(date.year, date.month, date.day));

  void invalidateCache() { _cache.clear(); _datesWithEntries.clear(); }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DailyEntryModel _entryToModel(DailyEntry e) => DailyEntryModel(
    id:              e.id,
    entryDate:       e.entryDate,
    openingBalance:  e.openingBalance,
    dailyCollection: e.dailyCollection,
    shopTotal:       e.shopTotal,
    personalTotal:   e.personalTotal,
    closingBalance:  e.closingBalance,
    cornerNumber:    e.cornerNumber,
    notes:           e.notes,
    isSynced:        e.isSynced,
    syncedAt:        e.syncedAt,
    createdAt:       e.createdAt,
  );

  EntryItemModel _itemToModel(EntryItem i) => EntryItemModel(
    id:           i.id,
    dailyEntryId: i.dailyEntryId,
    type:         i.type,
    label:        i.label,
    amount:       i.amount,
    sortOrder:    i.sortOrder,
    isSynced:     i.isSynced,
    createdAt:    i.createdAt,
  );
}
