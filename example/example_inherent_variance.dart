// ignore_for_file: avoid_print

/// Demonstrates why taking the minimum is not always appropriate.
///
/// Some developers prefer using the minimum (fastest) time as the benchmark
/// result, arguing that slower times are noise from GC, OS scheduling, etc.
/// This is valid when variance is external to the code being measured.
///
/// However, when variance is inherent to the algorithm (due to cache behavior,
/// branch prediction, or input-dependent performance), the minimum represents
/// a best-case that rarely occurs in practice.
///
/// This example uses synthetic data to clearly illustrate the distinction.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('\n--- Why Minimum Is Not Always Best ---\n');

  // Scenario: Two algorithms with different variance characteristics
  //
  // Algorithm A: Has a fast path (10%) and slow path (90%)
  //   - Minimum shows the fast path
  //   - But users experience the slow path most of the time
  //
  // Algorithm B: Consistent performance, slightly faster than A's slow path
  //   - Minimum and median are similar
  //   - What you measure is what you get

  final algorithmASamples = <double>[
    // Fast path (10% of cases): 2.0 us
    2.0,
    // Slow path (90% of cases): 8.0 us
    8.1, 8.0, 7.9, 8.2, 8.0, 7.8, 8.1, 8.0, 8.3,
  ];

  final algorithmBSamples = <double>[
    // Consistent performance: ~6.0 us
    6.1, 5.9, 6.0, 6.2, 5.8, 6.0, 6.1, 5.9, 6.0, 6.1,
  ];

  print('Algorithm A (has fast path that rarely triggers):');
  print('  Samples: $algorithmASamples');
  print('  Minimum: ${min(algorithmASamples).toStringAsFixed(1)} us');
  print('  Median:  ${median(algorithmASamples).toStringAsFixed(1)} us');
  print('  CV%:     ${cv(algorithmASamples).toStringAsFixed(1)}%');
  print('');

  print('Algorithm B (consistent performance):');
  print('  Samples: $algorithmBSamples');
  print('  Minimum: ${min(algorithmBSamples).toStringAsFixed(1)} us');
  print('  Median:  ${median(algorithmBSamples).toStringAsFixed(1)} us');
  print('  CV%:     ${cv(algorithmBSamples).toStringAsFixed(1)}%');
  print('');

  print('Analysis:');
  print('');
  print('  Using MINIMUM: A (2.0 us) appears 3x faster than B (5.8 us)');
  print('  Using MEDIAN:  B (6.0 us) is actually faster than A (8.0 us)');
  print('');
  print('  The minimum of A represents a fast path that only triggers 10%');
  print('  of the time. In production, users experience the slow path.');
  print('');
  print(
    '  The high CV% of A (${cv(algorithmASamples).toStringAsFixed(0)}%) signals inherent variance.',
  );
  print(
    '  The low CV% of B (${cv(algorithmBSamples).toStringAsFixed(0)}%) confirms consistent behavior.',
  );
  print('');

  print('When to use minimum vs median:');
  print('');
  print('  Use MINIMUM when:');
  print('    - Comparing pure algorithms with equivalent behavior');
  print('    - Variance comes from external noise (GC, OS scheduling)');
  print('    - You want to know "how fast CAN this code run?"');
  print('');
  print('  Use MEDIAN when:');
  print('    - Variance is inherent to the algorithm');
  print('    - Performance depends on input characteristics or cache state');
  print('    - You want to know "how fast WILL this code typically run?"');
  print('');
  print('  The CV% helps distinguish these cases:');
  print('    - High CV% with few extreme outliers -> likely external noise');
  print('    - High CV% with spread across range -> likely inherent variance');

  // Now demonstrate with real code
  print('');
  print('--- Real Code Demonstration ---');
  print('');

  const size = 10000;
  final data = List<int>.generate(size, (final i) => i);

  // Search positions that will be cycled through
  // This creates inherent variance: early positions are fast, late positions are slow
  final searchPositions = [
    0,
    100,
    500,
    1000,
    2500,
    5000,
    7500,
    9000,
    9500,
    9999,
  ];
  var searchIndex = 0;

  final benchmark = Benchmark(
    title: 'List Search (Position-Dependent)',
    variants: [
      BenchmarkVariant(
        name: 'indexOf',
        run: () {
          final target = searchPositions[searchIndex % searchPositions.length];
          searchIndex++;
          data.indexOf(target);
        },
      ),
    ],
    config: const BenchmarkConfig(
      iterations: 100, // Fewer iterations so position variance shows in samples
      samples: 10,
      warmupIterations: 50,
    ),
  );

  final results = benchmark.run(log: print);

  final result = results.first;
  print('');
  print('List.indexOf with varying target positions:');
  print('  Minimum: ${min(result.samples).toStringAsFixed(2)} us');
  print('  Median:  ${median(result.samples).toStringAsFixed(2)} us');
  print('  Maximum: ${max(result.samples).toStringAsFixed(2)} us');
  print('  CV%:     ${result.cv.toStringAsFixed(1)}%');
  print('');
  print('  The variance here is NOT noise. It reflects real performance');
  print('  differences based on where the target element is located.');
  print('  Using the minimum would misrepresent typical lookup cost.');
}
