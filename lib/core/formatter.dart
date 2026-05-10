// lib/core/formatter.dart

import 'package:intl/intl.dart';

/// Formatting utilities for Roj Med.
class RojMedFormatter {
  RojMedFormatter._();

  // Indian Rupee format: ₹1,00,000.00
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // Compact: ₹1,00,000 (no decimals for display chips)
  static final NumberFormat _currencyCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Format as Indian currency with decimals: ₹1,00,000.00
  static String currency(double amount) => _currency.format(amount);

  /// Format as Indian currency without decimals: ₹1,00,000
  static String currencyCompact(double amount) => _currencyCompact.format(amount);

  /// Format date as: Mon, 8 Jan 2026
  static String dateDisplay(DateTime date) =>
      DateFormat('EEE, d MMM yyyy').format(date);

  /// Format date as: 8 Jan 2026
  static String dateShort(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  /// Format date as: January 2026 (for month headers)
  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  /// Format date as: 2026-01-08 (for DB storage)
  static String dateForDb(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  /// Parse DB date string to DateTime
  static DateTime parseDateFromDb(String dateStr) =>
      DateFormat('yyyy-MM-dd').parse(dateStr);

  /// Format time: 3:45 PM
  static String timeDisplay(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  /// Format last synced label: "Just now", "5 min ago", "2 hrs ago"
  static String lastSynced(DateTime? lastSync) {
    if (lastSync == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)    return '${diff.inHours} hr ago';
    return dateShort(lastSync);
  }

  /// Strip non-numeric characters for amount parsing
  static double parseAmount(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
