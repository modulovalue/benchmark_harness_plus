// ignore_for_file: avoid_print

/// Shows different configuration presets.
library;

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  print('\n--- Configuration Presets ---\n');

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
