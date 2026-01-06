// ignore_for_file: avoid_print

/// Example demonstrating the value of statistically rigorous benchmarking.
///
/// This example compares different approaches to a common task and shows
/// how benchmark_harness_plus provides reliable, actionable insights.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('=== benchmark_harness_plus Example ===\n');

  // Example 1: Basic usage - comparing list operations
  basicExample();

  // Example 2: Why median matters - demonstrating outlier resistance
  outlierExample();

  // Example 3: Using different configurations
  configurationExample();

  // Example 4: Detailed analysis
  detailedAnalysisExample();
}

/// Basic usage: Compare different approaches to building a list.
void basicExample() {
  print('--- Example 1: List Building Strategies ---\n');

  final benchmark = Benchmark(
    title: 'List Building',
    variants: [
      BenchmarkVariant(
        name: 'growable',
        run: () {
          final list = <int>[];
          for (var i = 0; i < 100; i++) {
            list.add(i);
          }
        },
      ),
      BenchmarkVariant(
        name: 'fixed-length',
        run: () {
          final list = List<int>.filled(100, 0);
          for (var i = 0; i < 100; i++) {
            list[i] = i;
          }
        },
      ),
      BenchmarkVariant(
        name: 'generate',
        run: () {
          List<int>.generate(100, (i) => i);
        },
      ),
    ],
    config: BenchmarkConfig.quick, // Fast for demo purposes
  );

  final results = benchmark.run(log: print);
  printResults(results, baselineName: 'growable');
  printReliabilityWarning(results);
}

/// Demonstrates why median is better than mean for benchmarks.
///
/// In real benchmarks, outliers from GC, OS scheduling, etc. can
/// significantly skew the mean while the median remains stable.
void outlierExample() {
  print('\n--- Example 2: Why Median Matters ---\n');

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

/// Shows different configuration presets.
void configurationExample() {
  print('\n--- Example 3: Configuration Presets ---\n');

  print('BenchmarkConfig.quick:');
  print('  - ${BenchmarkConfig.quick.iterations} iterations/sample');
  print('  - ${BenchmarkConfig.quick.samples} samples');
  print('  - ${BenchmarkConfig.quick.warmupIterations} warmup iterations');
  print('  Use for: Quick feedback during development\n');

  print('BenchmarkConfig.standard (default):');
  print('  - ${BenchmarkConfig.standard.iterations} iterations/sample');
  print('  - ${BenchmarkConfig.standard.samples} samples');
  print('  - ${BenchmarkConfig.standard.warmupIterations} warmup iterations');
  print('  Use for: Normal benchmarking\n');

  print('BenchmarkConfig.thorough:');
  print('  - ${BenchmarkConfig.thorough.iterations} iterations/sample');
  print('  - ${BenchmarkConfig.thorough.samples} samples');
  print('  - ${BenchmarkConfig.thorough.warmupIterations} warmup iterations');
  print('  Use for: Important performance decisions\n');
}

/// Shows detailed analysis capabilities.
void detailedAnalysisExample() {
  print('\n--- Example 4: Detailed Analysis ---\n');

  final benchmark = Benchmark(
    title: 'String Concatenation',
    variants: [
      BenchmarkVariant(
        name: 'operator+',
        run: () {
          var s = '';
          for (var i = 0; i < 10; i++) {
            s = '${s}x';
          }
        },
      ),
      BenchmarkVariant(
        name: 'StringBuffer',
        run: () {
          final sb = StringBuffer();
          for (var i = 0; i < 10; i++) {
            sb.write('x');
          }
          sb.toString();
        },
      ),
    ],
    config: BenchmarkConfig.quick,
  );

  final results = benchmark.run(log: print);

  // Print detailed report for each result
  for (final result in results) {
    print(formatDetailedResult(result));
  }

  // Print comparison
  final comparison = BenchmarkComparison(
    baseline: results[0],
    test: results[1],
  );
  print(formatComparison(comparison));

  // Explain reliability
  print('Understanding CV% (Coefficient of Variation):');
  print('  < 10%:  Excellent - highly reliable measurements');
  print('  10-20%: Good - rankings are reliable');
  print('  20-50%: Moderate - directional only, do not trust exact ratios');
  print('  > 50%:  Poor - measurement is mostly noise');
}
