import 'package:flutter/material.dart';

/// Brand colors and the semantic palette used across WalletMate.
///
/// The whole Material 3 scheme is derived from [seed]; the values below cover
/// meanings Material does not model: income vs expense, and budget thresholds.
abstract final class AppColors {
  /// Deep green — the brand seed color.
  static const Color seed = Color(0xFF1B7F5E);

  /// Income amounts (light / dark theme).
  static const Color incomeLight = Color(0xFF1B7F5E);
  static const Color incomeDark = Color(0xFF6FD7AC);

  /// Expense amounts (light / dark theme).
  static const Color expenseLight = Color(0xFFB3261E);
  static const Color expenseDark = Color(0xFFFFB4AB);

  /// Budget progress in the 90%–99% band.
  static const Color warningLight = Color(0xFFB26A00);
  static const Color warningDark = Color(0xFFFFB955);

  /// Budget progress at or above 100%.
  static const Color dangerLight = Color(0xFFB3261E);
  static const Color dangerDark = Color(0xFFFFB4AB);

  /// Per-category colors of the dashboard expense chart. Keys match the
  /// category dictionary from the project specification.
  static const Map<String, Color> categories = {
    'food': Color(0xFF1B7F5E),
    'transport': Color(0xFF3F7FBF),
    'housing': Color(0xFF8C5BB0),
    'utilities': Color(0xFF00897B),
    'health': Color(0xFFD1495B),
    'education': Color(0xFF4C6EF5),
    'entertainment': Color(0xFFE07A5F),
    'shopping': Color(0xFFCB8B00),
    'other': Color(0xFF6B7280),
    'salary': Color(0xFF1B7F5E),
    'scholarship': Color(0xFF3F7FBF),
    'freelance': Color(0xFF8C5BB0),
    'gift': Color(0xFFE07A5F),
  };

  /// Fallback for a category missing from [categories].
  static const Color categoryFallback = Color(0xFF6B7280);

  static Color categoryColor(String category) =>
      categories[category] ?? categoryFallback;
}
