import 'statistics.dart' as stats;

/// Results from benchmarking a single variant.
///
/// Contains all collected samples and provides computed statistics.
/// The primary comparison metric is [median], which is robust against
/// outliers common in benchmark data.
///
/// Example:
/// ```dart
/// final result = benchmark.run().first;
/// print('Median: ${result.median.toStringAsFixed(2)} us/op');
/// print('CV%: ${result.cv.toStringAsFixed(1)}%');
/// if (result.reliability == ReliabilityLevel.excellent) {
///   print('Measurement is highly reliable');
/// }
/// ```
class BenchmarkResult {
  /// The name of the benchmarked variant.
  final String name;

  /// All collected sample measurements in microseconds per operation.
  ///
  /// Each sample represents the average time for one operation during
  /// that sampling period. The number of samples equals
  /// [BenchmarkConfig.samples].
  final List<double> samples;

  /// Creates a benchmark result.
  BenchmarkResult({
    required this.name,
    required this.samples,
  });

  /// The arithmetic mean (average) of all samples in microseconds.
  ///
  /// Compare with [median] to detect distribution skew:
  /// - mean approximately equals median: symmetric distribution
  /// - mean > median: high outliers present (common)
  /// - mean < median: low outliers present (rare)
  double get mean => stats.mean(samples);

  /// The median (middle value) of all samples in microseconds.
  ///
  /// **This is the primary metric for comparing benchmark variants.**
  ///
  /// The median ignores outliers caused by GC pauses, OS scheduling,
  /// and other system interference, providing a stable representation
  /// of typical performance.
  double get median => stats.median(samples);

  /// The sample standard deviation in microseconds.
  ///
  /// Measures how spread out the samples are from the mean.
  /// Smaller values indicate more consistent measurements.
  double get stdDev => stats.stdDev(samples);

  /// The coefficient of variation as a percentage.
  ///
  /// Normalizes variance across different scales, allowing comparison
  /// of measurement stability between fast and slow operations.
  ///
  /// **Trust thresholds:**
  /// - < 10%: Highly reliable
  /// - 10-20%: Acceptable
  /// - 20-50%: Directional only
  /// - > 50%: Unreliable
  ///
  /// See [reliability] for a categorized assessment.
  double get cv => stats.cv(samples);

  /// The minimum sample value in microseconds.
  ///
  /// Represents best-case performance, though this is often less
  /// meaningful than median for analysis.
  double get min => stats.min(samples);

  /// The maximum sample value in microseconds.
  ///
  /// High max relative to median indicates outliers, which is
  /// expected and normal for benchmark data.
  double get max => stats.max(samples);

  /// The reliability level based on coefficient of variation.
  ///
  /// Provides a quick assessment of how trustworthy this measurement is.
  /// See [ReliabilityLevel] for detailed descriptions.
  stats.ReliabilityLevel get reliability => stats.reliabilityFromCV(cv);

  /// Calculates the speedup ratio compared to a baseline result.
  ///
  /// Returns how many times faster this variant is compared to [baseline].
  /// A value > 1 means this variant is faster; < 1 means slower.
  ///
  /// Uses median for comparison to ignore outliers.
  ///
  /// Example:
  /// ```dart
  /// final speedup = optimized.speedupVs(baseline);
  /// print('Optimized is ${speedup.toStringAsFixed(2)}x faster');
  /// ```
  double speedupVs(BenchmarkResult baseline) {
    return baseline.median / median;
  }

  /// Calculates the percentage improvement compared to a baseline.
  ///
  /// Returns the percentage reduction in time compared to [baseline].
  /// Positive values indicate this variant is faster.
  ///
  /// Example:
  /// ```dart
  /// final improvement = optimized.improvementVs(baseline);
  /// print('Optimized is ${improvement.toStringAsFixed(1)}% faster');
  /// ```
  double improvementVs(BenchmarkResult baseline) {
    return ((baseline.median - median) / baseline.median) * 100;
  }

  @override
  String toString() => 'BenchmarkResult($name: '
      'median=${median.toStringAsFixed(2)}us, '
      'cv=${cv.toStringAsFixed(1)}%)';
}

/// Comparison between two benchmark results.
///
/// Provides detailed analysis of performance differences between
/// a test variant and a baseline.
class BenchmarkComparison {
  /// The baseline result being compared against.
  final BenchmarkResult baseline;

  /// The test result being compared.
  final BenchmarkResult test;

  /// Creates a comparison between two results.
  BenchmarkComparison({
    required this.baseline,
    required this.test,
  });

  /// Speedup ratio (baseline.median / test.median).
  ///
  /// Values > 1 indicate the test is faster than baseline.
  double get speedup => test.speedupVs(baseline);

  /// Percentage improvement ((baseline - test) / baseline * 100).
  ///
  /// Positive values indicate the test is faster.
  double get improvementPercent => test.improvementVs(baseline);

  /// Whether the comparison is statistically meaningful.
  ///
  /// Returns true if both measurements have acceptable reliability
  /// (CV < 20%). When false, treat comparisons as directional only.
  bool get isReliable {
    return baseline.cv < 20 && test.cv < 20;
  }

  /// Combined reliability level (worst of the two measurements).
  stats.ReliabilityLevel get reliability {
    final baselineRel = baseline.reliability;
    final testRel = test.reliability;
    // Return the worse reliability
    if (baselineRel.index > testRel.index) return baselineRel;
    return testRel;
  }

  @override
  String toString() {
    final direction = speedup >= 1 ? 'faster' : 'slower';
    final ratio = speedup >= 1 ? speedup : 1 / speedup;
    return '${test.name} is ${ratio.toStringAsFixed(2)}x $direction than ${baseline.name}';
  }
}
