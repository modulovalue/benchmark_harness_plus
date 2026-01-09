import 'dart:math' as math;

import 'config.dart';
import 'result.dart';

/// A benchmark variant to measure.
///
/// Wraps a piece of code with a name for identification in results.
///
/// Example:
/// ```dart
/// final variant = BenchmarkVariant(
///   name: 'list-growth',
///   run: () {
///     final list = <int>[];
///     for (var i = 0; i < 100; i++) list.add(i);
///   },
/// );
/// ```
class BenchmarkVariant {
  /// Human-readable name for this variant.
  ///
  /// Used in output tables and result identification.
  final String name;

  /// The code to benchmark.
  ///
  /// This function is called repeatedly during warmup and sampling.
  /// It should:
  /// - Be self-contained (no external state changes between calls)
  /// - Not include its own timing logic
  /// - Complete in a reasonable time (< 100ms for most cases)
  final void Function() run;

  /// Creates a benchmark variant.
  const BenchmarkVariant({
    required this.name,
    required this.run,
  });

  @override
  String toString() => 'BenchmarkVariant($name)';
}

/// Optional callback for benchmark progress reporting.
///
/// Called at various stages of benchmark execution to provide
/// visibility into progress.
typedef BenchmarkLogger = void Function(String message);

/// Runs benchmarks and collects statistically rigorous results.
///
/// The benchmark process:
/// 1. **Warmup**: Each variant runs [BenchmarkConfig.warmupIterations] times
///    to trigger JIT compilation and cache warming.
/// 2. **Sampling**: For each of [BenchmarkConfig.samples] samples:
///    - Variants are optionally shuffled to reduce ordering bias
///    - Each variant runs [BenchmarkConfig.iterations] times
///    - The time per operation is recorded
///
/// Example:
/// ```dart
/// final benchmark = Benchmark(
///   title: 'String Concatenation',
///   variants: [
///     BenchmarkVariant(
///       name: 'operator+',
///       run: () => 'hello' + ' ' + 'world',
///     ),
///     BenchmarkVariant(
///       name: 'interpolation',
///       run: () => '${'hello'} ${'world'}',
///     ),
///     BenchmarkVariant(
///       name: 'StringBuffer',
///       run: () => (StringBuffer()..write('hello')..write(' ')..write('world')).toString(),
///     ),
///   ],
/// );
///
/// final results = benchmark.run(log: print);
/// ```
class Benchmark {
  /// Title of the benchmark, displayed in output.
  final String title;

  /// The variants to compare.
  ///
  /// Must contain at least one variant. The first variant is typically
  /// used as the baseline for comparison ratios.
  final List<BenchmarkVariant> variants;

  /// Configuration controlling iterations, samples, and warmup.
  final BenchmarkConfig config;

  /// Creates a benchmark.
  ///
  /// [title] is displayed in output headers.
  /// [variants] must contain at least one variant to measure.
  /// [config] defaults to [BenchmarkConfig.standard].
  Benchmark({
    required this.title,
    required this.variants,
    this.config = const BenchmarkConfig(),
  }) : assert(variants.isNotEmpty, 'Must provide at least one variant');

  /// Runs the benchmark and returns results for all variants.
  ///
  /// [log] is an optional callback for progress messages. Pass `print`
  /// for console output, or a custom logger for integration with
  /// test frameworks.
  ///
  /// Returns a list of [BenchmarkResult] in the same order as [variants].
  List<BenchmarkResult> run({final BenchmarkLogger? log}) {
    final logger = log ?? ((final _) {});
    final random = math.Random();
    final results = <String, List<double>>{};

    for (final v in variants) {
      results[v.name] = [];
    }

    // Warmup phase
    logger('[$title] Warming up ${variants.length} variant(s)...');
    for (final v in variants) {
      for (var i = 0; i < config.warmupIterations; i++) {
        v.run();
      }
    }

    // Sampling phase
    logger('[$title] Collecting ${config.samples} sample(s)...');
    for (var sample = 0; sample < config.samples; sample++) {
      // Optionally randomize order to reduce systematic bias
      final order = List<int>.generate(variants.length, (final i) => i);
      if (config.randomizeOrder) {
        order.shuffle(random);
      }

      for (final idx in order) {
        final v = variants[idx];

        // Measure iterations
        final sw = Stopwatch()..start();
        for (var i = 0; i < config.iterations; i++) {
          v.run();
        }
        sw.stop();

        final usPerOp = sw.elapsedMicroseconds / config.iterations;
        results[v.name]!.add(usPerOp);
      }
    }

    logger('[$title] Done.');

    return variants
        .map((final v) =>
            BenchmarkResult(name: v.name, samples: results[v.name]!))
        .toList();
  }

  @override
  String toString() => 'Benchmark($title, ${variants.length} variants)';
}
