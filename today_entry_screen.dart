// lib/providers/entry_provider.dart

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../core/calculator.dart';
import '../core/constants.dart';
import '../data/local/database.dart';
import '../data/local/tables.dart';
import '../core/sync_service.dart';

/// Lightweight controller wrapper so provider doesn't need flutter import for TextEditingController.
/// Actual controllers are created in the screen widget.
class EntryLine {
  String id;
  String label;
  double amount;

  EntryLine({this.id = '', this.label = '', this.amount = 0.0});

  EntryLine copyWith({String? id, String? label, double? amount}) =>
      EntryLine(id: id ?? this.id, label: label ?? this.label, amount: amount ?? this.amount);

  bool get isEmpty => label.trim().isEmpty && amount == 0;
}

class EntryProvider extends ChangeNotifier {
  final _db = database;

  // ── State ─────────────────────────────────────────────────
  bool   _isLoading        = false;
  bool   _isSaving         = false;
  String? _error;
  String? _existingEntryId;

  DateTime _selectedDate   = DateTime.now();
  double   _openingBalance = 0.0;
  double   _dailyCollection = 0.0;
  List<EntryLine> _shopLines     = [EntryLine()];
  List<EntryLine> _personalLines = [EntryLine()];

  // ── Getters ───────────────────────────────────────────────
  bool    get isLoading        => _isLoading;
  bool    get isSaving         => _isSaving;
  String? get error            => _error;
  bool    get hasExistingEntry => _existingEntryId != null;
  String? get existingEntryId  => _existingEntryId;

  DateTime get selectedDate    => _selectedDate;
  double   get openingBalance  => _openingBalance;
  double   get dailyCollection => _dailyCollection;

  List<EntryLine> get shopLines     => _shopLines;
  List<EntryLine> get personalLines => _personalLines;

  double get shopTotal =>
      RojMedCalculator.shopTotal(_shopLines.map((e) => e.amount).toList());

  double get personalTotal =>
      RojMedCalculator.personalTotal(_personalLines.map((e) => e.amount).toList());

  double get closingBalance => RojMedCalculator.closingBalance(
    openingBalance:  _openingBalance,
    dailyCollection: _dailyCollection,
    shopTotal:       shopTotal,
    personalTotal:   personalTotal,
  );

  int get cornerNumber => RojMedCalculator.cornerNumber(_dailyCollection);

  // ── Load entry for a date ─────────────────────────────────

  Future<void> loadEntry(DateTime date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();

    try {
      // Try to load existing entry
      final existing = await _db.entriesDao.getEntryByDate(date);

      if (existing != null) {
        _existingEntryId  = existing.id;
        _openingBalance   = existing.openingBalance;
        _dailyCollection  = existing.dailyCollection;

        // Load items
        final shopItems     = await _db.itemsDao.getShopItems(existing.id);
        final personalItems = await _db.itemsDao.getPersonalItems(existing.id);

        _shopLines = shopItems.isNotEmpty
            ? shopItems.map((i) => EntryLine(id: i.id, label: i.label, amount: i.amount)).toList()
            : [EntryLine()];

        _personalLines = personalItems.isNotEmpty
            ? personalItems.map((i) => EntryLine(id: i.id, label: i.label, amount: i.amount)).toList()
            : [EntryLine()];
      } else {
        // New entry — auto-fill opening balance from yesterday
        _existingEntryId = null;
        _dailyCollection = 0.0;
        _shopLines       = [EntryLine()];
        _personalLines   = [EntryLine()];

        final yesterday = await _db.entriesDao.getYesterdayEntry(date);
        _openingBalance  = yesterday?.closingBalance ?? 0.0;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Field updates ─────────────────────────────────────────

  void setOpeningBalance(double v)  { _openingBalance  = v; notifyListeners(); }
  void setDailyCollection(double v) { _dailyCollection = v; notifyListeners(); }

  void updateShopLine(int index, {String? label, double? amount}) {
    if (index < _shopLines.length) {
      _shopLines[index] = _shopLines[index].copyWith(label: label, amount: amount);
      notifyListeners();
    }
  }

  void updatePersonalLine(int index, {String? label, double? amount}) {
    if (index < _personalLines.length) {
      _personalLines[index] = _personalLines[index].copyWith(label: label, amount: amount);
      notifyListeners();
    }
  }

  void addShopLine()     { _shopLines.add(EntryLine());     notifyListeners(); }
  void addPersonalLine() { _personalLines.add(EntryLine()); notifyListeners(); }

  void removeShopLine(int index) {
    if (_shopLines.length > 1) { _shopLines.removeAt(index); notifyListeners(); }
  }

  void removePersonalLine(int index) {
    if (_personalLines.length > 1) { _personalLines.removeAt(index); notifyListeners(); }
  }

  // ── Save ──────────────────────────────────────────────────

  Future<bool> saveEntry() async {
    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      final entryId = _existingEntryId ?? _generateId();
      final now     = DateTime.now();
      final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      // Write entry
      await _db.entriesDao.upsertEntry(DailyEntriesCompanion(
        id:              Value(entryId),
        entryDate:       Value(dateOnly),
        openingBalance:  Value(_openingBalance),
        dailyCollection: Value(_dailyCollection),
        shopTotal:       Value(shopTotal),
        personalTotal:   Value(personalTotal),
        closingBalance:  Value(closingBalance),
        cornerNumber:    Value(cornerNumber),
        isSynced:        const Value(false),
        createdAt:       Value(now),
      ));

      _existingEntryId = entryId;

      // Delete old items and re-insert
      await _db.itemsDao.deleteItemsForEntry(entryId);

      final validShop = _shopLines.where((l) => !l.isEmpty).toList();
      final validPers = _personalLines.where((l) => !l.isEmpty).toList();

      for (int i = 0; i < validShop.length; i++) {
        final l = validShop[i];
        await _db.itemsDao.insertItem(EntryItemsCompanion(
          id:           Value(l.id.isEmpty ? _generateId() : l.id),
          dailyEntryId: Value(entryId),
          type:         const Value(kTypeShop),
          label:        Value(l.label),
          amount:       Value(l.amount),
          sortOrder:    Value(i),
          isSynced:     const Value(false),
        ));
      }

      for (int i = 0; i < validPers.length; i++) {
        final l = validPers[i];
        await _db.itemsDao.insertItem(EntryItemsCompanion(
          id:           Value(l.id.isEmpty ? _generateId() : l.id),
          dailyEntryId: Value(entryId),
          type:         const Value(kTypePersonal),
          label:        Value(l.label),
          amount:       Value(l.amount),
          sortOrder:    Value(i),
          isSynced:     const Value(false),
        ));
      }

      // Trigger background sync
      SyncService.instance.syncEntry(entryId);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error    = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteEntry() async {
    if (_existingEntryId == null) return;
    await _db.itemsDao.deleteItemsForEntry(_existingEntryId!);
    await _db.entriesDao.deleteEntry(_existingEntryId!);
    _existingEntryId = null;
    _shopLines       = [EntryLine()];
    _personalLines   = [EntryLine()];
    _dailyCollection = 0.0;
    notifyListeners();
  }

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'local-$now';
  }
}
