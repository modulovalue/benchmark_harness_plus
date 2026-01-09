/// A statistically rigorous benchmarking harness for Dart.
///
/// This package provides reliable performance measurements using statistical
/// best practices: median-based comparisons, coefficient of variation for
/// reliability assessment, proper warmup phases, and outlier-resistant analysis.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';
///
/// void main() {
///   final benchmark = Benchmark(
///     title: 'String Operations',
///     variants: [
///       BenchmarkVariant(name: 'concat', run: () => 'a' + 'b' + 'c'),
///       BenchmarkVariant(name: 'interpolation', run: () => '${'a'}${'b'}${'c'}'),
///     ],
///   );
///
///   final results = benchmark.run(log: print);
///   printResults(results);
/// }
/// ```
///
/// ## Why Use This Package?
///
/// Traditional benchmarking often uses mean (average) for comparisons, which
/// is sensitive to outliers from GC pauses, OS scheduling, and CPU throttling.
/// This package uses **median** as the primary metric, providing stable
/// measurements even with occasional outliers.
///
/// The **coefficient of variation (CV%)** tells you how reliable your
/// measurements are:
/// - CV < 10%: Highly reliable
/// - CV 10-20%: Acceptable
/// - CV 20-50%: Directional only
/// - CV > 50%: Unreliable (measurement is noise)
///
/// ## Configuration
///
/// Use predefined configurations or create custom ones:
///
/// ```dart
/// // Quick feedback during development
/// Benchmark(..., config: BenchmarkConfig.quick);
///
/// // Standard benchmarking (default)
/// Benchmark(..., config: BenchmarkConfig.standard);
///
/// // Important performance decisions
/// Benchmark(..., config: BenchmarkConfig.thorough);
///
/// // Custom configuration
/// Benchmark(..., config: BenchmarkConfig(
///   iterations: 5000,
///   samples: 15,
///   warmupIterations: 1000,
/// ));
/// ```
///
/// ## Interpreting Results
///
/// 1. **Look at CV% first** - if > 20%, treat comparisons as directional only
/// 2. **Compare medians** - this is your primary metric
/// 3. **Check mean vs median** - large difference indicates outliers
/// 4. **Look at the ratio** - 1.42x means 42% faster than baseline
///
/// ## Best Practices
///
/// - Use at least 10 samples (20 for important decisions)
/// - Each sample should take at least 10ms (adjust iterations accordingly)
/// - Always warm up before measuring
/// - Report CV% alongside results
/// - Re-run when results seem surprising
library benchmark_harness_plus;

export 'src/benchmark.dart' show Benchmark, BenchmarkVariant, BenchmarkLogger;
export 'src/config.dart' show BenchmarkConfig;
export 'src/printer.dart'
    show
        formatComparison,
        formatDetailedResult,
        formatResults,
        formatResultsAsCsv,
        printReliabilityWarning,
        printResults;
export 'src/result.dart' show BenchmarkComparison, BenchmarkResult;
export 'src/statistics.dart'
    show
        ReliabilityLevel,
        cv,
        max,
        mean,
        median,
        min,
        reliabilityFromCV,
        stdDev;
