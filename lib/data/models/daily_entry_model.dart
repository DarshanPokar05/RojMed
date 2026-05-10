// lib/data/models/daily_entry_model.dart

import 'entry_item.dart';

/// Full domain model for one day's entry including all items.
class DailyEntryModel {
  final String   id;
  final DateTime entryDate;
  final double   openingBalance;
  final double   dailyCollection;
  final double   shopTotal;
  final double   personalTotal;
  final double   closingBalance;
  final int      cornerNumber;
  final String?  notes;
  final bool     isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;

  // Items (loaded separately, joined in provider)
  final List<EntryItemModel> shopItems;
  final List<EntryItemModel> personalItems;

  const DailyEntryModel({
    required this.id,
    required this.entryDate,
    required this.openingBalance,
    required this.dailyCollection,
    required this.shopTotal,
    required this.personalTotal,
    required this.closingBalance,
    required this.cornerNumber,
    this.notes,
    required this.isSynced,
    this.syncedAt,
    required this.createdAt,
    this.shopItems     = const [],
    this.personalItems = const [],
  });

  DailyEntryModel copyWith({
    String?   id,
    DateTime? entryDate,
    double?   openingBalance,
    double?   dailyCollection,
    double?   shopTotal,
    double?   personalTotal,
    double?   closingBalance,
    int?      cornerNumber,
    String?   notes,
    bool?     isSynced,
    DateTime? syncedAt,
    DateTime? createdAt,
    List<EntryItemModel>? shopItems,
    List<EntryItemModel>? personalItems,
  }) {
    return DailyEntryModel(
      id:              id              ?? this.id,
      entryDate:       entryDate       ?? this.entryDate,
      openingBalance:  openingBalance  ?? this.openingBalance,
      dailyCollection: dailyCollection ?? this.dailyCollection,
      shopTotal:       shopTotal       ?? this.shopTotal,
      personalTotal:   personalTotal   ?? this.personalTotal,
      closingBalance:  closingBalance  ?? this.closingBalance,
      cornerNumber:    cornerNumber    ?? this.cornerNumber,
      notes:           notes           ?? this.notes,
      isSynced:        isSynced        ?? this.isSynced,
      syncedAt:        syncedAt        ?? this.syncedAt,
      createdAt:       createdAt       ?? this.createdAt,
      shopItems:       shopItems       ?? this.shopItems,
      personalItems:   personalItems   ?? this.personalItems,
    );
  }

  /// Convert to Supabase-compatible map
  Map<String, dynamic> toSupabaseMap() => {
    'id':               id,
    'entry_date':       entryDate.toIso8601String().split('T').first,
    'opening_balance':  openingBalance,
    'daily_collection': dailyCollection,
    'shop_total':       shopTotal,
    'personal_total':   personalTotal,
    'closing_balance':  closingBalance,
    'corner_number':    cornerNumber,
    'notes':            notes,
    'synced_at':        DateTime.now().toIso8601String(),
  };

  /// Create from Supabase map
  factory DailyEntryModel.fromSupabaseMap(Map<String, dynamic> map) {
    return DailyEntryModel(
      id:              map['id'] as String,
      entryDate:       DateTime.parse(map['entry_date'] as String),
      openingBalance:  (map['opening_balance'] as num).toDouble(),
      dailyCollection: (map['daily_collection'] as num).toDouble(),
      shopTotal:       (map['shop_total'] as num).toDouble(),
      personalTotal:   (map['personal_total'] as num).toDouble(),
      closingBalance:  (map['closing_balance'] as num).toDouble(),
      cornerNumber:    (map['corner_number'] as num).toInt(),
      notes:           map['notes'] as String?,
      isSynced:        true,
      syncedAt:        map['synced_at'] != null
                         ? DateTime.parse(map['synced_at'] as String)
                         : null,
      createdAt:       map['created_at'] != null
                         ? DateTime.parse(map['created_at'] as String)
                         : DateTime.now(),
    );
  }
}
