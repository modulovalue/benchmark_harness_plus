/// A type-safe representation of a percentage value.
///
/// Stores the value as a ratio (0.0-1.0) internally, but provides
/// convenient accessors for both ratio and percentage formats.
///
/// Example:
/// ```dart
/// final p = Percentage.fromRatio(1, 4);   // 25%
/// final p2 = Percentage.fromPercent(25);  // also 25%
///
/// print(p.asRatio);    // 0.25
/// print(p.asPercent);  // 25.0
/// print(p);            // 25.0%
/// ```
final class Percentage implements Comparable<Percentage> {
  /// The value as a ratio from 0.0 to 1.0 (and beyond for values > 100%).
  final double asRatio;

  const Percentage._(this.asRatio);

  /// A percentage representing 0%.
  static const zero = Percentage._(0);

  /// Creates a percentage from a ratio (numerator / denominator).
  ///
  /// Example: `Percentage.fromRatio(1, 4)` represents 25%.
  Percentage.fromRatio(final double numerator, final double denominator)
      : this._(denominator != 0 ? numerator / denominator : 0);

  /// Creates a percentage from a percent value (0-100).
  ///
  /// Example: `Percentage.fromPercent(25)` represents 25%.
  const Percentage.fromPercent(final double percent) : this._(percent / 100);

  /// The value as a percentage from 0 to 100 (and beyond for values > 100%).
  double get asPercent => asRatio * 100;

  /// Formats the percentage for display.
  ///
  /// [fractionDigits] controls decimal places (default: 1).
  ///
  /// Example: `Percentage(0.256).toStringAsPercent()` returns `"25.6%"`.
  String toStringAsPercent([final int fractionDigits = 1]) =>
      '${asPercent.toStringAsFixed(fractionDigits)}%';

  @override
  String toString() => toStringAsPercent();

  @override
  int compareTo(final Percentage other) => asRatio.compareTo(other.asRatio);

  @override
  bool operator ==(final Object other) =>
      other is Percentage && asRatio == other.asRatio;

  @override
  int get hashCode => asRatio.hashCode;

  bool operator <(final Percentage other) => asRatio < other.asRatio;

  bool operator <=(final Percentage other) => asRatio <= other.asRatio;

  bool operator >(final Percentage other) => asRatio > other.asRatio;

  bool operator >=(final Percentage other) => asRatio >= other.asRatio;
}
