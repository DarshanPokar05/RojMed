// lib/data/remote/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_entry_model.dart';
import '../models/entry_item.dart';
import '../../core/constants.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Daily Entries ─────────────────────────────────────────

  /// Upsert a daily entry to Supabase
  Future<void> upsertEntry(DailyEntryModel entry) async {
    await _client
        .from(kTableDailyEntries)
        .upsert(entry.toSupabaseMap(), onConflict: 'entry_date');
  }

  /// Fetch all entries for a month from Supabase
  Future<List<DailyEntryModel>> fetchEntriesForMonth(int year, int month) async {
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final end   = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    final response = await _client
        .from(kTableDailyEntries)
        .select()
        .gte('entry_date', start)
        .lt('entry_date', end)
        .order('entry_date', ascending: true);

    return (response as List)
        .map((m) => DailyEntryModel.fromSupabaseMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single entry by date
  Future<DailyEntryModel?> fetchEntryByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _client
        .from(kTableDailyEntries)
        .select()
        .eq('entry_date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return DailyEntryModel.fromSupabaseMap(response as Map<String, dynamic>);
  }

  /// Fetch all entries (for full sync on app open)
  Future<List<DailyEntryModel>> fetchAllEntries() async {
    final response = await _client
        .from(kTableDailyEntries)
        .select()
        .order('entry_date', ascending: false);

    return (response as List)
        .map((m) => DailyEntryModel.fromSupabaseMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Delete an entry from Supabase
  Future<void> deleteEntry(String entryId) async {
    await _client
        .from(kTableDailyEntries)
        .delete()
        .eq('id', entryId);
  }

  // ── Entry Items ───────────────────────────────────────────

  /// Upsert all items for an entry (replaces existing)
  Future<void> upsertItems(List<EntryItemModel> items) async {
    if (items.isEmpty) return;
    final maps = items.map((i) => i.toSupabaseMap()).toList();
    await _client.from(kTableEntryItems).upsert(maps);
  }

  /// Fetch all items for an entry
  Future<List<EntryItemModel>> fetchItemsForEntry(String entryId) async {
    final response = await _client
        .from(kTableEntryItems)
        .select()
        .eq('daily_entry_id', entryId)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((m) => EntryItemModel.fromSupabaseMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Delete all items for an entry (before re-upserting)
  Future<void> deleteItemsForEntry(String entryId) async {
    await _client
        .from(kTableEntryItems)
        .delete()
        .eq('daily_entry_id', entryId);
  }

  // ── App Settings ──────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final response = await _client
        .from(kTableAppSettings)
        .select('value')
        .eq('key', key)
        .maybeSingle();
    return response?['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await _client
        .from(kTableAppSettings)
        .upsert({'key': key, 'value': value});
  }

  // ── Auth (Email OTP for Forgot PIN) ───────────────────────

  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<bool> verifyOtp(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      return response.session != null;
    } catch (_) {
      return false;
    }
  }
}
