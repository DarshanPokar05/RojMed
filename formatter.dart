// lib/core/calculator.dart

/// Central calculation engine for Roj Med.
/// All business logic lives here — no calculation happens in UI layer.
class RojMedCalculator {
  RojMedCalculator._(); // prevent instantiation

  /// Sum of all shop item amounts.
  static double shopTotal(List<double> shopAmounts) {
    return shopAmounts.fold(0.0, (sum, a) => sum + a);
  }

  /// Sum of all personal spend amounts.
  static double personalTotal(List<double> personalAmounts) {
    return personalAmounts.fold(0.0, (sum, a) => sum + a);
  }

  /// Closing balance carried forward to next day's opening balance.
  ///
  /// Formula:
  ///   closingBalance = openingBalance + (dailyCollection - shopTotal - personalTotal)
  static double closingBalance({
    required double openingBalance,
    required double dailyCollection,
    required double shopTotal,
    required double personalTotal,
  }) {
    return openingBalance + (dailyCollection - shopTotal - personalTotal);
  }

  /// Corner number shown at top-right of each diary page.
  ///
  /// Formula:
  ///   cornerNumber = ceil(dailyCollection / 1000) × 10
  ///
  /// Examples:
  ///   dailyCollection = 3200 → ceil(3.2)  × 10 = 40
  ///   dailyCollection = 1000 → ceil(1.0)  × 10 = 10
  ///   dailyCollection = 2550 → ceil(2.55) × 10 = 30
  ///   dailyCollection =  500 → ceil(0.5)  × 10 = 10
  ///   dailyCollection =    0 → 0
  static int cornerNumber(double dailyCollection) {
    if (dailyCollection <= 0) return 0;
    return (dailyCollection / 1000).ceil() * 10;
  }

  /// Monthly totals for the summary screen.
  static MonthlySummary monthlySummary({
    required List<DailyTotals> days,
  }) {
    double totalDailyCollection = 0;
    double totalShopSpend       = 0;
    double totalPersonalSpend   = 0;
    int    totalCornerNumbers   = 0;

    for (final day in days) {
      totalDailyCollection += day.dailyCollection;
      totalShopSpend       += day.shopTotal;
      totalPersonalSpend   += day.personalTotal;
      totalCornerNumbers   += day.cornerNumber;
    }

    return MonthlySummary(
      totalDailyCollection: totalDailyCollection,
      totalShopSpend:       totalShopSpend,
      totalPersonalSpend:   totalPersonalSpend,
      totalCornerNumbers:   totalCornerNumbers,
    );
  }
}

/// Lightweight data holder for one day's totals (used in monthly calc).
class DailyTotals {
  final double dailyCollection;
  final double shopTotal;
  final double personalTotal;
  final int    cornerNumber;

  const DailyTotals({
    required this.dailyCollection,
    required this.shopTotal,
    required this.personalTotal,
    required this.cornerNumber,
  });
}

/// Result of monthly summary calculation.
class MonthlySummary {
  final double totalDailyCollection;
  final double totalShopSpend;
  final double totalPersonalSpend;
  final int    totalCornerNumbers;

  const MonthlySummary({
    required this.totalDailyCollection,
    required this.totalShopSpend,
    required this.totalPersonalSpend,
    required this.totalCornerNumbers,
  });
}
