import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Today" as the app sees it — the default month of the dashboard and the
/// budgets, the `Сегодня` header, the date of a new operation.
///
/// Read through a provider rather than `DateTime.now()` so tests can pin it:
/// the demo data is laid out relative to this date, and a test that ran on a
/// different day would otherwise see different months.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
