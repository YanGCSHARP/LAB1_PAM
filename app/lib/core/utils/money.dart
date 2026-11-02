/// Arithmetic on money amounts.
///
/// Amounts are `double` throughout the app (the backend's `decimal(18,2)`
/// arrives as a JSON number), but sums are taken in whole cents: adding
/// `249.90 + 420.00 + ...` in floating point drifts by fractions of a cent,
/// and a budget at exactly 90 % must not come out as 89.999… %.
abstract final class Money {
  static int toCents(double amount) => (amount * 100).round();

  static double fromCents(int cents) => cents / 100;

  /// Rounds to two decimals, the precision of `decimal(18,2)`.
  static double round(double amount) => fromCents(toCents(amount));

  /// Sum of [amounts], exact to the cent.
  static double sum(Iterable<double> amounts) {
    var cents = 0;
    for (final amount in amounts) {
      cents += toCents(amount);
    }
    return fromCents(cents);
  }

  /// `part / whole`, computed on cents; `0` when [whole] is not positive.
  static double ratio(double part, double whole) {
    final wholeCents = toCents(whole);
    if (wholeCents <= 0) {
      return 0;
    }
    return toCents(part) / wholeCents;
  }
}
