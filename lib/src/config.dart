/// Configuration for benchmark execution.
///
/// Controls how many iterations, samples, and warmup runs are performed.
/// Proper configuration is crucial for reliable measurements.
library;

/// Configuration for benchmark runs.
///
/// A benchmark run consists of:
/// 1. **Warmup phase**: Runs each variant [warmupIterations] times to allow
///    JIT compilation and cache warming. Results are discarded.
/// 2. **Sampling phase**: Collects [samples] measurements, where each sample
///    times [iterations] executions of the code under test.
///
/// Example:
/// ```dart
/// // Custom configuration for a slow operation
/// final config = BenchmarkConfig(
///   iterations: 100,      // Fewer iterations for slow code
///   samples: 20,          // More samples for statistical confidence
///   warmupIterations: 50,
/// );
/// ```
class BenchmarkConfig {
  /// Number of iterations per sample.
  ///
  /// Each sample measures the time to execute the benchmark code this many
  /// times, then computes the average time per operation. Higher values
  /// reduce measurement overhead noise but increase total benchmark time.
  ///
  /// **Guidelines:**
  /// - Fast operations (< 1us): Use 10000+ iterations
  /// - Medium operations (1us - 1ms): Use 1000 iterations
  /// - Slow operations (> 1ms): Use 10-100 iterations
  ///
  /// The goal is for each sample to take at least 10ms to minimize
  /// timer resolution effects.
  final int iterations;

  /// Number of samples to collect.
  ///
  /// Each sample is an independent measurement. More samples provide
  /// better statistical confidence and more reliable median/CV calculations.
  ///
  /// **Guidelines:**
  /// - Quick checks: 5 samples minimum
  /// - Normal benchmarks: 10 samples
  /// - Important decisions: 20+ samples
  final int samples;

  /// Number of warmup iterations before sampling begins.
  ///
  /// Warmup allows the Dart VM to JIT-compile hot paths and warm up
  /// CPU caches. Results from warmup are discarded.
  ///
  /// **Guidelines:**
  /// - Simple code: 100-500 iterations
  /// - Complex code with many paths: 1000+ iterations
  /// - AOT-compiled code: Can use fewer iterations
  final int warmupIterations;

  /// Whether to randomize the order of variants between samples.
  ///
  /// When true (default), variants are measured in random order for each
  /// sample, reducing systematic bias from:
  /// - CPU frequency scaling
  /// - Thermal throttling
  /// - Memory pressure changes over time
  ///
  /// Set to false only when you need reproducible ordering for debugging.
  final bool randomizeOrder;

  /// Creates a benchmark configuration.
  ///
  /// All parameters have sensible defaults for typical benchmarks.
  const BenchmarkConfig({
    this.iterations = 1000,
    this.samples = 10,
    this.warmupIterations = 500,
    this.randomizeOrder = true,
  });

  /// Quick benchmark configuration for fast feedback.
  ///
  /// Use this during development to get rapid estimates. Results may have
  /// higher variance (CV%) due to fewer samples.
  ///
  /// - 100 iterations per sample
  /// - 5 samples
  /// - 50 warmup iterations
  static const quick = BenchmarkConfig(
    iterations: 100,
    samples: 5,
    warmupIterations: 50,
  );

  /// Standard benchmark configuration (default).
  ///
  /// Balanced configuration suitable for most benchmarks. Provides
  /// reasonable accuracy without excessive runtime.
  ///
  /// - 1000 iterations per sample
  /// - 10 samples
  /// - 500 warmup iterations
  static const standard = BenchmarkConfig();

  /// Thorough benchmark configuration for important decisions.
  ///
  /// Use this when benchmark results will influence significant decisions.
  /// Takes longer but provides higher statistical confidence.
  ///
  /// - 10000 iterations per sample
  /// - 20 samples
  /// - 1000 warmup iterations
  static const thorough = BenchmarkConfig(
    iterations: 10000,
    samples: 20,
    warmupIterations: 1000,
  );

  @override
  String toString() => 'BenchmarkConfig('
      'iterations: $iterations, '
      'samples: $samples, '
      'warmupIterations: $warmupIterations, '
      'randomizeOrder: $randomizeOrder)';
}
