/// Statistical functions for analyzing benchmark samples.
///
/// These functions provide the mathematical foundation for reliable
/// performance comparisons. The key insight is that benchmark data
/// typically contains outliers (GC pauses, OS scheduling, CPU throttling),
/// so median-based analysis is preferred over mean-based analysis.
library;

import 'dart:math' as math;

/// Calculates the arithmetic mean (average) of a list of samples.
///
/// The mean is sensitive to outliers, so it should be used alongside
/// [median] to detect distribution skew:
/// - mean approximately equals median: symmetric distribution
/// - mean > median: high outliers present (common in benchmarks)
/// - mean < median: low outliers present (rare)
///
/// Returns 0 if [samples] is empty.
///
/// Example:
/// ```dart
/// final avg = mean([1.0, 2.0, 3.0, 4.0, 5.0]); // 3.0
/// ```
double mean(final List<double> samples) {
  if (samples.isEmpty) return 0;
  return samples.reduce((final a, final b) => a + b) / samples.length;
}

/// Calculates the median (middle value) of a list of samples.
///
/// **This is the primary metric for benchmark comparisons.**
///
/// The median ignores outliers, making it ideal for benchmark data.
/// If 9 runs take 5us and 1 run takes 50us (due to GC), the median
/// remains at 5us, accurately representing typical performance.
///
/// For even-length lists, returns the average of the two middle values.
/// Returns 0 if [samples] is empty.
///
/// Example:
/// ```dart
/// final mid = median([1.0, 2.0, 100.0]); // 2.0 (ignores the outlier)
/// ```
double median(final List<double> samples) {
  if (samples.isEmpty) return 0;
  final sorted = List<double>.from(samples)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Calculates the sample standard deviation of a list of samples.
///
/// Standard deviation measures how spread out the samples are from the mean.
/// Uses Bessel's correction (n-1 denominator) for unbiased estimation
/// from a sample.
///
/// Interpretation:
/// - Small stddev relative to mean = stable, trustworthy measurements
/// - Large stddev relative to mean = high variance, less reliable
///
/// Returns 0 if [samples] has fewer than 2 elements.
///
/// Example:
/// ```dart
/// final sd = stdDev([10.0, 10.1, 9.9, 10.0]); // ~0.08 (very stable)
/// final sd2 = stdDev([5.0, 15.0, 25.0, 35.0]); // ~12.9 (high variance)
/// ```
double stdDev(final List<double> samples) {
  if (samples.length < 2) return 0;
  final m = mean(samples);
  final variance =
      samples
          .map((final s) => math.pow(s - m, 2))
          .reduce((final a, final b) => a + b) /
      (samples.length - 1);
  return math.sqrt(variance);
}

/// Calculates the coefficient of variation (CV) as a percentage.
///
/// CV normalizes the standard deviation by the mean, allowing comparison
/// of measurement stability across different scales (e.g., comparing
/// the reliability of 1us vs 1000us measurements).
///
/// Formula: `(stdDev / mean) * 100`
///
/// **Trust thresholds for benchmark data:**
/// - CV < 10%: Highly reliable, trust the comparisons
/// - CV 10-20%: Acceptable, rankings are reliable
/// - CV 20-50%: Directional only, do not trust exact ratios
/// - CV > 50%: Unreliable, measurement is mostly noise
///
/// Returns 0 if [samples] is empty or mean is zero.
///
/// Example:
/// ```dart
/// final reliability = cv([10.0, 10.1, 9.9, 10.0]); // ~0.8% (excellent)
/// final reliability2 = cv([5.0, 15.0, 25.0]); // ~66% (unreliable)
/// ```
double cv(final List<double> samples) {
  final m = mean(samples);
  return m > 0 ? (stdDev(samples) / m) * 100 : 0;
}

/// Returns the minimum value in [samples].
///
/// Useful for understanding the best-case performance, though this
/// is often less meaningful than median for benchmark analysis.
///
/// Throws [StateError] if [samples] is empty.
double min(final List<double> samples) {
  return samples.reduce((final a, final b) => a < b ? a : b);
}

/// Returns the maximum value in [samples].
///
/// High max values relative to median indicate outliers, which is
/// expected in benchmark data due to GC, OS scheduling, etc.
///
/// Throws [StateError] if [samples] is empty.
double max(final List<double> samples) {
  return samples.reduce((final a, final b) => a > b ? a : b);
}

/// Describes the reliability level of a measurement based on its CV%.
enum ReliabilityLevel {
  /// CV < 10%: Highly reliable, trust the comparisons.
  excellent,

  /// CV 10-20%: Acceptable, rankings are reliable.
  good,

  /// CV 20-50%: Directional only, do not trust exact ratios.
  moderate,

  /// CV > 50%: Unreliable, measurement is mostly noise.
  poor,
}

/// Determines the reliability level based on coefficient of variation.
///
/// See [ReliabilityLevel] for threshold descriptions.
ReliabilityLevel reliabilityFromCV(final double cvPercent) {
  if (cvPercent < 10) return ReliabilityLevel.excellent;
  if (cvPercent < 20) return ReliabilityLevel.good;
  if (cvPercent < 50) return ReliabilityLevel.moderate;
  return ReliabilityLevel.poor;
}
