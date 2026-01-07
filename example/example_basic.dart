// ignore_for_file: avoid_print

/// Basic usage: Compare different approaches to building a list.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('--- List Building Strategies ---\n');

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
          List<int>.generate(100, (final i) => i);
        },
      ),
    ],
    config: BenchmarkConfig.quick, // Fast for demo purposes
  );

  final results = benchmark.run(log: print);
  printResults(results, baselineName: 'growable');
  printReliabilityWarning(results);
}
