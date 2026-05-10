// lib/data/models/entry_item.dart

/// Domain model for a single shop or personal spend line item.
class EntryItemModel {
  final String   id;
  final String   dailyEntryId;
  final String   type;   // 'shop' | 'personal'
  final String   label;
  final double   amount;
  final int      sortOrder;
  final bool     isSynced;
  final DateTime createdAt;

  const EntryItemModel({
    required this.id,
    required this.dailyEntryId,
    required this.type,
    required this.label,
    required this.amount,
    required this.sortOrder,
    required this.isSynced,
    required this.createdAt,
  });

  EntryItemModel copyWith({
    String?   id,
    String?   dailyEntryId,
    String?   type,
    String?   label,
    double?   amount,
    int?      sortOrder,
    bool?     isSynced,
    DateTime? createdAt,
  }) {
    return EntryItemModel(
      id:           id           ?? this.id,
      dailyEntryId: dailyEntryId ?? this.dailyEntryId,
      type:         type         ?? this.type,
      label:        label        ?? this.label,
      amount:       amount       ?? this.amount,
      sortOrder:    sortOrder    ?? this.sortOrder,
      isSynced:     isSynced     ?? this.isSynced,
      createdAt:    createdAt    ?? this.createdAt,
    );
  }

  Map<String, dynamic> toSupabaseMap() => {
    'id':             id,
    'daily_entry_id': dailyEntryId,
    'type':           type,
    'label':          label,
    'amount':         amount,
    'sort_order':     sortOrder,
  };

  factory EntryItemModel.fromSupabaseMap(Map<String, dynamic> map) {
    return EntryItemModel(
      id:           map['id'] as String,
      dailyEntryId: map['daily_entry_id'] as String,
      type:         map['type'] as String,
      label:        map['label'] as String,
      amount:       (map['amount'] as num).toDouble(),
      sortOrder:    (map['sort_order'] as num? ?? 0).toInt(),
      isSynced:     true,
      createdAt:    map['created_at'] != null
                      ? DateTime.parse(map['created_at'] as String)
                      : DateTime.now(),
    );
  }

  /// For UI: temporary item with no DB id yet
  factory EntryItemModel.empty({
    required String entryId,
    required String type,
    int sortOrder = 0,
  }) {
    return EntryItemModel(
      id:           '',
      dailyEntryId: entryId,
      type:         type,
      label:        '',
      amount:       0.0,
      sortOrder:    sortOrder,
      isSynced:     false,
      createdAt:    DateTime.now(),
    );
  }

  bool get isEmpty => label.trim().isEmpty && amount == 0;
  bool get isShop  => type == 'shop';
}
