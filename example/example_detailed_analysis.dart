// ignore_for_file: avoid_print

/// Shows detailed analysis capabilities.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('\n--- Detailed Analysis ---\n');

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

  printResults(results);
  printReliabilityWarning(results);

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
