// ignore_for_file: avoid_print

/// Demonstrates why median is better than mean for benchmarks.
///
/// In real benchmarks, outliers from GC, OS scheduling, etc. can
/// significantly skew the mean while the median remains stable.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('\n--- Why Median Matters ---\n');

  // Simulate benchmark data with outliers (like GC pauses)
  final samplesWithOutliers = [
    5.1, 5.0, 5.2, 4.9, 5.0, // Normal measurements
    5.1, 5.0, 50.0, 5.1, 5.0, // One outlier (GC pause)
  ];

  print('Sample data: $samplesWithOutliers');
  print('');
  print('Mean:   ${mean(samplesWithOutliers).toStringAsFixed(2)} us');
  print('Median: ${median(samplesWithOutliers).toStringAsFixed(2)} us');
  print('');
  print('The mean (${mean(samplesWithOutliers).toStringAsFixed(2)}) is skewed by the outlier.');
  print('The median (${median(samplesWithOutliers).toStringAsFixed(2)}) accurately represents typical performance.');
  print('');
  print('This is why benchmark_harness_plus uses median for comparisons!');
}
