# benchmark_harness_plus

A statistically rigorous benchmarking harness for Dart. Provides median-based comparisons, coefficient of variation, proper warmup phases, and outlier-resistant measurements for reliable performance analysis.

## Why This Package?

The standard `benchmark_harness` package uses mean (average) for measurements, which is sensitive to outliers from GC pauses, OS scheduling, and CPU throttling. This package uses **median** as the primary metric, providing stable measurements even with occasional outliers.

```
Sample data with one GC pause: [5.0, 5.1, 4.9, 5.0, 50.0]

Mean:   14.0 us  (skewed by outlier)
Median:  5.0 us  (accurate representation)
```

## Features

- **Median-based comparisons**: Robust against outliers
- **Coefficient of variation (CV%)**: Know how reliable your measurements are
- **Proper warmup**: JIT compilation and cache warming before measurement
- **Randomized ordering**: Reduces systematic bias from CPU throttling
- **Multiple samples**: Statistical confidence, not single-shot measurements
- **Detailed reporting**: Full statistics with reliability assessment

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  benchmark_harness_plus: ^1.0.0
```

## Quick Start

```dart
import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  final benchmark = Benchmark(
    title: 'String Operations',
    variants: [
      BenchmarkVariant(
        name: 'concat',
        run: () => 'a' + 'b' + 'c',
      ),
      BenchmarkVariant(
        name: 'interpolation',
        run: () => '${'a'}${'b'}${'c'}',
      ),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results);
}
```

Output:

```
[String Operations] Warming up 2 variant(s)...
[String Operations] Collecting 10 sample(s)...
[String Operations] Done.

  Variant        |     median |       mean |    fastest |   stddev |    cv% |  vs base
  ------------------------------------------------------------------------------------
  concat         |       0.42 |       0.43 |       0.40 |     0.02 |    4.7 |        -
  interpolation  |       0.38 |       0.39 |       0.36 |     0.01 |    3.2 |    1.11x

  (times in microseconds per operation)
```

## Configuration00

Use predefined configurations or create custom ones:

```dart
// Quick feedback during development (less accurate)
Benchmark(..., config: BenchmarkConfig.quick);

// Standard benchmarking (default)
Benchmark(..., config: BenchmarkConfig.standard);

// Important performance decisions (more accurate)
Benchmark(..., config: BenchmarkConfig.thorough);

// Custom configuration
Benchmark(..., config: BenchmarkConfig(
  iterations: 5000,     // Iterations per sample
  samples: 15,          // Number of samples to collect
  warmupIterations: 1000,
  randomizeOrder: true, // Randomize variant order
));
```

## Understanding CV% (Coefficient of Variation)

CV% normalizes variance across different scales. It tells you how reliable your measurements are:

| CV%    | Reliability | Interpretation |
|--------|-------------|----------------|
| < 10%  | Excellent   | Highly reliable, trust exact ratios |
| 10-20% | Good        | Rankings are reliable |
| 20-50% | Moderate    | Directional only, do not trust exact ratios |
| > 50%  | Poor        | Unreliable, measurement is mostly noise |

```dart
final result = benchmark.run().first;
print('Reliability: ${result.reliability}'); // excellent, good, moderate, or poor
```

## Interpreting Results

1. **Look at CV% first**: If > 20%, treat comparisons as directional only
2. **Compare medians**: This is your primary metric
3. **Check mean vs median**: Large difference indicates outliers
4. **Look at the ratio**: 1.42x means 42% faster than baseline

## Detailed Analysis

```dart
final results = benchmark.run();

// Detailed report for a single result
print(formatDetailedResult(results[0]));

// Compare two variants
final comparison = BenchmarkComparison(
  baseline: results[0],
  test: results[1],
);
print('Speedup: ${comparison.speedup.toStringAsFixed(2)}x');
print('Improvement: ${comparison.improvementPercent.toStringAsFixed(1)}%');
print('Reliable: ${comparison.isReliable}');

// Export as CSV
final csv = formatResultsAsCsv(results);
File('results.csv').writeAsStringSync(csv);
```

## Statistical Functions

The package exports individual statistical functions for custom analysis:

```dart
import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

final samples = [10.0, 11.0, 9.5, 10.2, 10.1];

print('Mean: ${mean(samples)}');
print('Median: ${median(samples)}');
print('Stddev: ${stdDev(samples)}');
print('CV%: ${cv(samples)}');
print('Range: ${min(samples)} - ${max(samples)}');
print('Reliability: ${reliabilityFromCV(cv(samples))}');
```

## Best Practices

1. **Use enough samples**: Minimum 10, prefer 20 for important decisions
2. **Use enough iterations**: Each sample should take at least 10ms
3. **Warm up properly**: JIT needs time to optimize hot paths
4. **Report CV%**: Always show measurement stability
5. **Use median for comparisons**: More robust than mean
6. **Re-run when in doubt**: If results seem surprising, verify with another run

## Common Pitfalls

- **Sub-microsecond measurements**: Inherently noisy, expect CV% > 50%
- **First run bias**: Always warm up before measuring
- **Order effects**: Randomize variant order across samples (enabled by default)
- **Single sample**: Never trust a single measurement

## Learn More

**[BENCHMARKING_GUIDE.md](BENCHMARKING_GUIDE.md)** - In-depth explanation of:
- The statistical foundations behind each metric
- Benefits and downsides of mean, median, stddev, and CV%
- How to interpret results correctly
- What to do when measurements are unreliable
- How to choose the right configuration

**[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Migrating from benchmark_harness:
- Side-by-side code comparisons
- Step-by-step migration instructions
- Common migration patterns
- What you gain by switching

## License

MIT License. See LICENSE file for details.
