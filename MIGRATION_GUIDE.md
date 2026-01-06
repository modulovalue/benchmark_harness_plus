# Migration Guide: benchmark_harness to benchmark_harness_plus

This guide helps you migrate from the standard `benchmark_harness` package to `benchmark_harness_plus`.

## Quick Comparison

| Feature | benchmark_harness | benchmark_harness_plus |
|---------|-------------------|------------------------|
| Primary metric | Mean | Median |
| Outlier handling | None | Automatic (median-based) |
| Reliability indicator | None | CV% with thresholds |
| Multiple variants | Manual setup | Built-in comparison |
| Warmup | Automatic | Automatic + configurable |
| Sample collection | Single measurement | Multiple samples |
| Output format | Single number | Full statistical table |

## Basic Migration

### Before: benchmark_harness

```dart
import 'package:benchmark_harness/benchmark_harness.dart';

class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('MyBenchmark');

  @override
  void run() {
    // Code to benchmark
    doSomething();
  }
}

void main() {
  MyBenchmark().report();
}
```

Output:
```
MyBenchmark(RunTime): 1234.56 us.
```

### After: benchmark_harness_plus

```dart
import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';

void main() {
  final benchmark = Benchmark(
    title: 'MyBenchmark',
    variants: [
      BenchmarkVariant(
        name: 'default',
        run: () {
          // Code to benchmark
          doSomething();
        },
      ),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results);
}
```

Output:
```
[MyBenchmark] Warming up 1 variant(s)...
[MyBenchmark] Collecting 10 sample(s)...
[MyBenchmark] Done.

  Variant |     median |       mean |   stddev |    cv% |  vs base
  ----------------------------------------------------------------
  default |    1234.56 |    1240.23 |    15.32 |    1.2 |        -

  (times in microseconds per operation)
```

## Step-by-Step Migration

### Step 1: Update pubspec.yaml

```yaml
# Remove
dev_dependencies:
  benchmark_harness: ^2.0.0

# Add
dev_dependencies:
  benchmark_harness_plus: ^1.0.0
```

### Step 2: Update imports

```dart
// Remove
import 'package:benchmark_harness/benchmark_harness.dart';

// Add
import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';
```

### Step 3: Convert benchmark classes to variants

**Before:**
```dart
class ListGrowBenchmark extends BenchmarkBase {
  ListGrowBenchmark() : super('ListGrow');

  @override
  void run() {
    final list = <int>[];
    for (var i = 0; i < 100; i++) {
      list.add(i);
    }
  }
}

class ListFixedBenchmark extends BenchmarkBase {
  ListFixedBenchmark() : super('ListFixed');

  @override
  void run() {
    final list = List<int>.filled(100, 0);
    for (var i = 0; i < 100; i++) {
      list[i] = i;
    }
  }
}

void main() {
  ListGrowBenchmark().report();
  ListFixedBenchmark().report();
}
```

**After:**
```dart
void main() {
  final benchmark = Benchmark(
    title: 'List Creation',
    variants: [
      BenchmarkVariant(
        name: 'grow',
        run: () {
          final list = <int>[];
          for (var i = 0; i < 100; i++) {
            list.add(i);
          }
        },
      ),
      BenchmarkVariant(
        name: 'fixed',
        run: () {
          final list = List<int>.filled(100, 0);
          for (var i = 0; i < 100; i++) {
            list[i] = i;
          }
        },
      ),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results, baselineName: 'grow');
}
```

### Step 4: Migrate setup and teardown

**Before:**
```dart
class MyBenchmark extends BenchmarkBase {
  late List<int> data;

  MyBenchmark() : super('MyBenchmark');

  @override
  void setup() {
    data = List.generate(1000, (i) => i);
  }

  @override
  void teardown() {
    data.clear();
  }

  @override
  void run() {
    data.sort();
  }
}
```

**After:**
```dart
void main() {
  // Setup before creating the benchmark
  var data = List.generate(1000, (i) => i);

  final benchmark = Benchmark(
    title: 'MyBenchmark',
    variants: [
      BenchmarkVariant(
        name: 'sort',
        run: () {
          // Reset data before each run if needed
          data = List.generate(1000, (i) => i);
          data.sort();
        },
      ),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results);

  // Teardown after benchmark
  data.clear();
}
```

For benchmarks that need per-iteration setup without measuring the setup time, include only the relevant code in the `run` function and accept that setup is included. Alternatively, use a pattern like:

```dart
void main() {
  // Pre-generate test data
  final testInputs = List.generate(
    10000, // More than iterations * samples
    (i) => List.generate(1000, (j) => j)..shuffle(),
  );
  var inputIndex = 0;

  final benchmark = Benchmark(
    title: 'Sort Benchmark',
    variants: [
      BenchmarkVariant(
        name: 'sort',
        run: () {
          // Cycle through pre-generated inputs
          final data = testInputs[inputIndex % testInputs.length];
          inputIndex++;
          data.sort();
        },
      ),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results);
}
```

## Migrating Custom Exercise Counts

**Before:**
```dart
class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('MyBenchmark');

  @override
  void exercise() {
    // Custom: run 100 times instead of default 10
    for (var i = 0; i < 100; i++) {
      run();
    }
  }

  @override
  void run() {
    doSomething();
  }
}
```

**After:**
```dart
final benchmark = Benchmark(
  title: 'MyBenchmark',
  variants: [
    BenchmarkVariant(
      name: 'default',
      run: () => doSomething(),
    ),
  ],
  config: BenchmarkConfig(
    iterations: 100,  // Equivalent to custom exercise count
    samples: 10,
    warmupIterations: 500,
  ),
);
```

## Migrating Emitter Usage

**Before:**
```dart
class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('MyBenchmark', emitter: MyCustomEmitter());

  @override
  void run() => doSomething();
}

class MyCustomEmitter extends ScoreEmitter {
  @override
  void emit(String testName, double value) {
    // Custom output handling
    print('RESULT: $testName = $value');
  }
}
```

**After:**
```dart
void main() {
  final benchmark = Benchmark(
    title: 'MyBenchmark',
    variants: [
      BenchmarkVariant(name: 'default', run: () => doSomething()),
    ],
  );

  final results = benchmark.run();

  // Custom output handling
  for (final result in results) {
    print('RESULT: ${result.name} = ${result.median}');
  }

  // Or use built-in formatters
  print(formatResults(results));           // Table format
  print(formatDetailedResult(results[0])); // Detailed single result
  print(formatResultsAsCsv(results));      // CSV for export
}
```

## What You Gain

### 1. Outlier Resistance

**Before:** A single GC pause could skew your results by 10x or more.

**After:** Median-based comparison ignores outliers automatically.

```
Samples: [5.0, 5.1, 4.9, 5.0, 50.0]  (GC pause on last run)

benchmark_harness mean:    14.0 us  (misleading)
benchmark_harness_plus median: 5.0 us  (accurate)
```

### 2. Reliability Assessment

**Before:** No way to know if your measurement is trustworthy.

**After:** CV% tells you exactly how reliable the measurement is.

```
  Variant |     median |   cv% |
  -----------------------------
  fast-op |       0.08 |  75.0 |  <- CV% > 50%: unreliable!
  slow-op |      15.23 |   3.2 |  <- CV% < 10%: excellent
```

### 3. Built-in Comparison

**Before:** Run benchmarks separately, manually calculate ratios.

**After:** Automatic side-by-side comparison with speedup ratios.

```
  Variant      |     median |  vs base
  ------------------------------------
  baseline     |      34.39 |        -
  optimized    |      24.15 |    1.42x  <- 42% faster
```

### 4. Multiple Samples

**Before:** Single measurement (even if internally averaged).

**After:** Multiple independent samples for statistical confidence.

### 5. Configurable Accuracy

**Before:** Fixed iteration count via exercise() override.

**After:** Presets for different needs:

```dart
BenchmarkConfig.quick     // Fast feedback during development
BenchmarkConfig.standard  // Normal benchmarking
BenchmarkConfig.thorough  // Important decisions
```

## Common Migration Patterns

### Pattern: Multiple related benchmarks

**Before:**
```dart
void main() {
  JsonEncodeBenchmark().report();
  JsonDecodeBenchmark().report();
  JsonRoundtripBenchmark().report();
}
```

**After:**
```dart
void main() {
  final benchmark = Benchmark(
    title: 'JSON Operations',
    variants: [
      BenchmarkVariant(name: 'encode', run: () => jsonEncode(data)),
      BenchmarkVariant(name: 'decode', run: () => jsonDecode(jsonString)),
      BenchmarkVariant(name: 'roundtrip', run: () => jsonDecode(jsonEncode(data))),
    ],
  );

  final results = benchmark.run(log: print);
  printResults(results, baselineName: 'encode');
}
```

### Pattern: Parameterized benchmarks

**Before:**
```dart
class SortBenchmark extends BenchmarkBase {
  final int size;
  late List<int> data;

  SortBenchmark(this.size) : super('Sort-$size');

  @override
  void setup() => data = List.generate(size, (i) => i)..shuffle();

  @override
  void run() => data.sort();
}

void main() {
  for (final size in [100, 1000, 10000]) {
    SortBenchmark(size).report();
  }
}
```

**After:**
```dart
void main() {
  for (final size in [100, 1000, 10000]) {
    var data = <int>[];

    final benchmark = Benchmark(
      title: 'Sort-$size',
      variants: [
        BenchmarkVariant(
          name: 'sort',
          run: () {
            data = List.generate(size, (i) => i)..shuffle();
            data.sort();
          },
        ),
      ],
    );

    final results = benchmark.run(log: print);
    printResults(results);
  }
}
```

## FAQ

### Q: Can I still get a single number like benchmark_harness?

Yes, just access the median directly:

```dart
final results = benchmark.run();
final microseconds = results.first.median;
print('$microseconds us');
```

### Q: What if I need the mean for compatibility?

```dart
final results = benchmark.run();
final meanMicroseconds = results.first.mean;
```

### Q: How do I silence the progress output?

Do not pass a logger:

```dart
final results = benchmark.run();  // No log parameter = silent
```

### Q: Is benchmark_harness_plus slower to run?

It collects more data (multiple samples), so yes, it takes longer. Use `BenchmarkConfig.quick` for fast iteration during development:

```dart
Benchmark(..., config: BenchmarkConfig.quick)
```

### Q: Can I use both packages in the same project?

Yes, but it is not recommended as they serve the same purpose. If you need to migrate gradually:

```dart
import 'package:benchmark_harness/benchmark_harness.dart' as old;
import 'package:benchmark_harness_plus/benchmark_harness_plus.dart' as new_;
```
