// ignore_for_file: avoid_print

/// Example demonstrating the value of statistically rigorous benchmarking.
///
/// This example compares different approaches to a common task and shows
/// how benchmark_harness_plus provides reliable, actionable insights.
library;

import 'example_basic.dart' as basic;
import 'example_configuration.dart' as configuration;
import 'example_detailed_analysis.dart' as detailed_analysis;
import 'example_inherent_variance.dart' as inherent_variance;
import 'example_outlier.dart' as outlier;

void main() {
  print('=== benchmark_harness_plus Example ===\n');

  // Basic usage, comparing list operations
  basic.main();

  // Why median matters, demonstrating outlier resistance
  outlier.main();

  // Using different configurations
  configuration.main();

  // Detailed analysis
  detailed_analysis.main();

  // Why minimum is not always best, inherent variance
  inherent_variance.main();
}
