import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';
import 'package:test/test.dart';

void main() {
  group('BenchmarkConfig', () {
    test('default values are sensible', () {
      const config = BenchmarkConfig();
      expect(config.iterations, equals(1000));
      expect(config.samples, equals(10));
      expect(config.warmupIterations, equals(500));
      expect(config.randomizeOrder, isTrue);
    });

    test('quick preset has fewer iterations', () {
      expect(BenchmarkConfig.quick.iterations,
          lessThan(BenchmarkConfig.standard.iterations));
      expect(BenchmarkConfig.quick.samples,
          lessThan(BenchmarkConfig.standard.samples));
    });

    test('thorough preset has more iterations', () {
      expect(BenchmarkConfig.thorough.iterations,
          greaterThan(BenchmarkConfig.standard.iterations));
      expect(BenchmarkConfig.thorough.samples,
          greaterThan(BenchmarkConfig.standard.samples));
    });

    test('custom config accepts parameters', () {
      const config = BenchmarkConfig(
        iterations: 500,
        samples: 15,
        warmupIterations: 200,
        randomizeOrder: false,
      );
      expect(config.iterations, equals(500));
      expect(config.samples, equals(15));
      expect(config.warmupIterations, equals(200));
      expect(config.randomizeOrder, isFalse);
    });

    test('toString includes all parameters', () {
      const config = BenchmarkConfig();
      final str = config.toString();
      expect(str, contains('iterations'));
      expect(str, contains('samples'));
      expect(str, contains('warmupIterations'));
      expect(str, contains('randomizeOrder'));
    });
  });

  group('BenchmarkVariant', () {
    test('stores name and function', () {
      var called = false;
      final variant = BenchmarkVariant(
        name: 'test-variant',
        run: () => called = true,
      );

      expect(variant.name, equals('test-variant'));
      variant.run();
      expect(called, isTrue);
    });

    test('toString includes name', () {
      final variant = BenchmarkVariant(name: 'my-variant', run: () {});
      expect(variant.toString(), contains('my-variant'));
    });
  });

  group('BenchmarkResult', () {
    test('computes statistics from samples', () {
      final result = BenchmarkResult(
        name: 'test',
        samples: [10.0, 11.0, 9.0, 10.0, 10.0],
      );

      expect(result.name, equals('test'));
      expect(result.mean, equals(10.0));
      expect(result.median, equals(10.0));
      expect(result.min, equals(9.0));
      expect(result.max, equals(11.0));
      expect(result.stdDev, greaterThan(0.0));
      expect(result.cv.asRatio, greaterThan(0.0));
    });

    test('speedupVs calculates ratio correctly', () {
      final baseline = BenchmarkResult(name: 'baseline', samples: [10.0, 10.0]);
      final faster = BenchmarkResult(name: 'faster', samples: [5.0, 5.0]);
      final slower = BenchmarkResult(name: 'slower', samples: [20.0, 20.0]);

      expect(faster.speedupVs(baseline), equals(2.0)); // 2x faster
      expect(slower.speedupVs(baseline), equals(0.5)); // 2x slower
      expect(baseline.speedupVs(baseline), equals(1.0)); // Same
    });

    test('improvementVs calculates percentage correctly', () {
      final baseline =
          BenchmarkResult(name: 'baseline', samples: [100.0, 100.0]);
      final improved = BenchmarkResult(name: 'improved', samples: [50.0, 50.0]);

      expect(
        improved.improvementVs(baseline).asPercent,
        equals(50.0),
      ); // 50% faster
    });

    test('reliability reflects CV thresholds', () {
      final excellent = BenchmarkResult(
        name: 'excellent',
        samples: [10.0, 10.01, 9.99, 10.0], // Very low variance
      );
      expect(excellent.reliability, equals(ReliabilityLevel.excellent));

      final poor = BenchmarkResult(
        name: 'poor',
        samples: [1.0, 50.0, 100.0], // Very high variance
      );
      expect(poor.reliability, equals(ReliabilityLevel.poor));
    });

    test('toString includes key info', () {
      final result = BenchmarkResult(name: 'test', samples: [10.0, 10.0]);
      final str = result.toString();
      expect(str, contains('test'));
      expect(str, contains('median'));
      expect(str, contains('cv'));
    });
  });

  group('BenchmarkComparison', () {
    late BenchmarkResult baselineResult;
    late BenchmarkResult testResult;

    setUp(() {
      baselineResult = BenchmarkResult(name: 'baseline', samples: [10.0, 10.0]);
      testResult = BenchmarkResult(name: 'test', samples: [5.0, 5.0]);
    });

    test('calculates speedup', () {
      final comparison =
          BenchmarkComparison(baseline: baselineResult, test: testResult);
      expect(comparison.speedup, equals(2.0));
    });

    test('calculates improvement percentage', () {
      final comparison =
          BenchmarkComparison(baseline: baselineResult, test: testResult);
      expect(comparison.improvement.asPercent, equals(50.0));
    });

    test('isReliable checks both CVs', () {
      final reliable1 = BenchmarkResult(
        name: 'r1',
        samples: [10.0, 10.01, 9.99, 10.0],
      );
      final reliable2 = BenchmarkResult(
        name: 'r2',
        samples: [5.0, 5.01, 4.99, 5.0],
      );
      final unreliable = BenchmarkResult(
        name: 'u',
        samples: [1.0, 50.0, 100.0],
      );

      expect(
        BenchmarkComparison(baseline: reliable1, test: reliable2).isReliable,
        isTrue,
      );
      expect(
        BenchmarkComparison(baseline: reliable1, test: unreliable).isReliable,
        isFalse,
      );
    });

    test('toString describes the comparison', () {
      final comparison =
          BenchmarkComparison(baseline: baselineResult, test: testResult);
      final str = comparison.toString();
      expect(str, contains('test'));
      expect(str, contains('baseline'));
      expect(str, contains('faster'));
    });
  });

  group('Benchmark', () {
    test('runs variants and returns results', () {
      var counter1 = 0;
      var counter2 = 0;

      final benchmark = Benchmark(
        title: 'Test Benchmark',
        variants: [
          BenchmarkVariant(name: 'v1', run: () => counter1++),
          BenchmarkVariant(name: 'v2', run: () => counter2++),
        ],
        config: const BenchmarkConfig(
          iterations: 10,
          samples: 3,
          warmupIterations: 5,
          randomizeOrder: false,
        ),
      );

      final results = benchmark.run();

      expect(results.length, equals(2));
      expect(results[0].name, equals('v1'));
      expect(results[1].name, equals('v2'));
      expect(results[0].samples.length, equals(3));
      expect(results[1].samples.length, equals(3));

      // Check variants were actually run
      // warmup: 5 each, samples: 3 * 10 each = 35 each
      expect(counter1, equals(35));
      expect(counter2, equals(35));
    });

    test('calls logger during execution', () {
      final logs = <String>[];

      final benchmark = Benchmark(
        title: 'Logging Test',
        variants: [BenchmarkVariant(name: 'v1', run: () {})],
        config: const BenchmarkConfig(
          iterations: 1,
          samples: 1,
          warmupIterations: 1,
        ),
      );

      benchmark.run(log: logs.add);

      expect(logs, isNotEmpty);
      expect(logs.any((final l) => l.contains('Warming up')), isTrue);
      expect(logs.any((final l) => l.contains('Collecting')), isTrue);
      expect(logs.any((final l) => l.contains('Done')), isTrue);
    });

    test('results have positive timing values', () {
      final benchmark = Benchmark(
        title: 'Timing Test',
        variants: [
          BenchmarkVariant(
            name: 'work',
            run: () {
              var sum = 0;
              for (var i = 0; i < 100; i++) {
                sum += i;
              }
              expect(sum, equals(4950));
            },
          ),
        ],
        config: const BenchmarkConfig(
          iterations: 100,
          samples: 3,
          warmupIterations: 10,
        ),
      );

      final results = benchmark.run();

      expect(results[0].median, greaterThan(0.0));
      expect(results[0].samples.every((final s) => s > 0), isTrue);
    });

    test('toString includes title and variant count', () {
      final benchmark = Benchmark(
        title: 'My Benchmark',
        variants: [
          BenchmarkVariant(name: 'v1', run: () {}),
          BenchmarkVariant(name: 'v2', run: () {}),
        ],
      );

      final str = benchmark.toString();
      expect(str, contains('My Benchmark'));
      expect(str, contains('2'));
    });
  });

  group('formatResults', () {
    test('formats results as table', () {
      final results = [
        BenchmarkResult(name: 'baseline', samples: [10.0, 10.0]),
        BenchmarkResult(name: 'optimized', samples: [5.0, 5.0]),
      ];

      final output = formatResults(results);

      expect(output, contains('Variant'));
      expect(output, contains('median'));
      expect(output, contains('mean'));
      expect(output, contains('baseline'));
      expect(output, contains('optimized'));
      expect(output, contains('2.00x')); // Speedup ratio
    });

    test('uses specified baseline', () {
      final results = [
        BenchmarkResult(name: 'a', samples: [10.0, 10.0]),
        BenchmarkResult(name: 'b', samples: [20.0, 20.0]),
      ];

      final output = formatResults(results, baselineName: 'b');
      // When b is baseline (20us), a (10us) is 2x faster
      expect(output, contains('2.00x'));
    });

    test('handles empty results', () {
      final output = formatResults([]);
      expect(output, contains('no results'));
    });
  });

  group('formatDetailedResult', () {
    test('includes all statistics', () {
      final result = BenchmarkResult(
        name: 'test',
        samples: [10.0, 11.0, 9.0, 10.0, 10.0],
      );

      final output = formatDetailedResult(result);

      expect(output, contains('test'));
      expect(output, contains('Median'));
      expect(output, contains('Mean'));
      expect(output, contains('Stddev'));
      expect(output, contains('CV%'));
      expect(output, contains('Range'));
      expect(output, contains('Reliability'));
    });
  });

  group('formatResultsAsCsv', () {
    test('produces valid CSV', () {
      final results = [
        BenchmarkResult(name: 'a', samples: [1.0, 2.0, 3.0]),
        BenchmarkResult(name: 'b', samples: [4.0, 5.0, 6.0]),
      ];

      final csv = formatResultsAsCsv(results);
      final lines = csv.trim().split('\n');

      expect(lines.length, equals(3)); // Header + 2 rows
      expect(lines[0], contains('name,median,mean'));
      expect(lines[1], startsWith('a,'));
      expect(lines[2], startsWith('b,'));
    });
  });
}
