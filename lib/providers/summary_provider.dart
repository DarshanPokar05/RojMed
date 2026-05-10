// lib/providers/summary_provider.dart

import 'package:flutter/foundation.dart';
import '../core/calculator.dart';
import '../data/local/database.dart';
import '../data/local/tables.dart';
import '../data/models/daily_entry_model.dart';

class MonthlySummaryData {
  final int    year;
  final int    month;
  final MonthlySummary totals;
  final List<DailyEntryModel> days;

  const MonthlySummaryData({
    required this.year,
    required this.month,
    required this.totals,
    required this.days,
  });
}

class SummaryProvider extends ChangeNotifier {
  final _db = database;

  bool                  _isLoading = false;
  MonthlySummaryData?   _current;
  String?               _error;

  bool                 get isLoading => _isLoading;
  MonthlySummaryData?  get current   => _current;
  String?              get error     => _error;

  Future<void> loadMonth(int year, int month) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final entries = await _db.entriesDao.getEntriesForMonth(year, month);
      final models  = entries.map((e) => DailyEntryModel(
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
      )).toList();

      final dailyTotals = models.map((m) => DailyTotals(
        dailyCollection: m.dailyCollection,
        shopTotal:       m.shopTotal,
        personalTotal:   m.personalTotal,
        cornerNumber:    m.cornerNumber,
      )).toList();

      final totals = RojMedCalculator.monthlySummary(days: dailyTotals);

      _current = MonthlySummaryData(
        year:   year,
        month:  month,
        totals: totals,
        days:   models,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void goToPreviousMonth() {
    if (_current == null) return;
    final m = _current!.month == 1 ? 12 : _current!.month - 1;
    final y = _current!.month == 1 ? _current!.year - 1 : _current!.year;
    loadMonth(y, m);
  }

  void goToNextMonth() {
    if (_current == null) return;
    final m = _current!.month == 12 ? 1 : _current!.month + 1;
    final y = _current!.month == 12 ? _current!.year + 1 : _current!.year;
    loadMonth(y, m);
  }
}
