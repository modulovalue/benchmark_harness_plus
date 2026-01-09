import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';
import 'package:test/test.dart';

void main() {
  group('mean', () {
    test('calculates average of values', () {
      expect(mean([1.0, 2.0, 3.0, 4.0, 5.0]), equals(3.0));
    });

    test('handles single value', () {
      expect(mean([42.0]), equals(42.0));
    });

    test('returns 0 for empty list', () {
      expect(mean([]), equals(0.0));
    });

    test('handles negative values', () {
      expect(mean([-2.0, -1.0, 0.0, 1.0, 2.0]), equals(0.0));
    });

    test('handles large values', () {
      expect(mean([1000000.0, 2000000.0, 3000000.0]), equals(2000000.0));
    });

    test('handles decimal precision', () {
      expect(mean([0.1, 0.2, 0.3]), closeTo(0.2, 0.0001));
    });
  });

  group('median', () {
    test('finds middle value in odd-length list', () {
      expect(median([1.0, 2.0, 3.0, 4.0, 5.0]), equals(3.0));
    });

    test('averages middle values in even-length list', () {
      expect(median([1.0, 2.0, 3.0, 4.0]), equals(2.5));
    });

    test('handles single value', () {
      expect(median([42.0]), equals(42.0));
    });

    test('returns 0 for empty list', () {
      expect(median([]), equals(0.0));
    });

    test('handles unsorted input', () {
      expect(median([5.0, 1.0, 3.0, 4.0, 2.0]), equals(3.0));
    });

    test('ignores outliers', () {
      // 9 values around 5, one outlier at 100
      final samples = [5.0, 5.1, 4.9, 5.0, 5.2, 4.8, 5.0, 5.1, 4.9, 100.0];
      expect(median(samples), closeTo(5.0, 0.1));
    });

    test('handles two values', () {
      expect(median([10.0, 20.0]), equals(15.0));
    });
  });

  group('stdDev', () {
    test('calculates sample standard deviation', () {
      // Sample: [2, 4, 4, 4, 5, 5, 7, 9]
      // Mean = 5, Variance = 32/7, StdDev = sqrt(32/7) ≈ 2.138
      expect(
        stdDev([2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]),
        closeTo(2.138, 0.001),
      );
    });

    test('returns 0 for single value', () {
      expect(stdDev([42.0]), equals(0.0));
    });

    test('returns 0 for empty list', () {
      expect(stdDev([]), equals(0.0));
    });

    test('returns 0 for identical values', () {
      expect(stdDev([5.0, 5.0, 5.0, 5.0]), equals(0.0));
    });

    test('handles two values', () {
      // [0, 10]: mean=5, variance=50, stddev=sqrt(50)≈7.07
      expect(stdDev([0.0, 10.0]), closeTo(7.07, 0.01));
    });

    test('uses Bessel correction (n-1)', () {
      // With n-1 (sample stddev): variance = sum((x-mean)^2) / (n-1)
      // With n (population stddev): variance = sum((x-mean)^2) / n
      // For [1, 2, 3]: mean=2, sum of squares=2
      // Sample stddev = sqrt(2/2) = 1.0
      // Population stddev = sqrt(2/3) ≈ 0.816
      expect(stdDev([1.0, 2.0, 3.0]), equals(1.0));
    });
  });

  group('cv', () {
    test('calculates coefficient of variation as percentage', () {
      // If stddev = 1 and mean = 10, CV = 10%
      final samples = [9.0, 10.0, 11.0]; // stddev=1, mean=10
      expect(cv(samples).asPercent, closeTo(10.0, 0.1));
    });

    test('returns 0 for empty list', () {
      expect(cv([]).asRatio, equals(0.0));
    });

    test('returns 0 for identical values', () {
      expect(cv([5.0, 5.0, 5.0, 5.0]).asRatio, equals(0.0));
    });

    test('returns 0 when mean is zero', () {
      expect(cv([-1.0, 0.0, 1.0]).asRatio, equals(0.0));
    });

    test('handles high variance', () {
      // Very spread out data should have high CV
      final samples = [1.0, 50.0, 100.0];
      expect(cv(samples).asPercent, greaterThan(50.0));
    });

    test('handles low variance', () {
      // Very consistent data should have low CV
      final samples = [100.0, 100.1, 99.9, 100.0, 100.05];
      expect(cv(samples).asPercent, lessThan(1.0));
    });
  });

  group('min', () {
    test('finds minimum value', () {
      expect(min([5.0, 2.0, 8.0, 1.0, 9.0]), equals(1.0));
    });

    test('handles single value', () {
      expect(min([42.0]), equals(42.0));
    });

    test('handles negative values', () {
      expect(min([5.0, -3.0, 2.0]), equals(-3.0));
    });

    test('throws on empty list', () {
      expect(() => min([]), throwsStateError);
    });
  });

  group('max', () {
    test('finds maximum value', () {
      expect(max([5.0, 2.0, 8.0, 1.0, 9.0]), equals(9.0));
    });

    test('handles single value', () {
      expect(max([42.0]), equals(42.0));
    });

    test('handles negative values', () {
      expect(max([-5.0, -3.0, -2.0]), equals(-2.0));
    });

    test('throws on empty list', () {
      expect(() => max([]), throwsStateError);
    });
  });

  group('reliabilityFromCV', () {
    test('returns excellent for CV < 10%', () {
      expect(
        reliabilityFromCV(const Percentage.fromPercent(0.0)),
        equals(ReliabilityLevel.excellent),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(5.0)),
        equals(ReliabilityLevel.excellent),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(9.9)),
        equals(ReliabilityLevel.excellent),
      );
    });

    test('returns good for CV 10-20%', () {
      expect(
        reliabilityFromCV(const Percentage.fromPercent(10.0)),
        equals(ReliabilityLevel.good),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(15.0)),
        equals(ReliabilityLevel.good),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(19.9)),
        equals(ReliabilityLevel.good),
      );
    });

    test('returns moderate for CV 20-50%', () {
      expect(
        reliabilityFromCV(const Percentage.fromPercent(20.0)),
        equals(ReliabilityLevel.moderate),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(35.0)),
        equals(ReliabilityLevel.moderate),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(49.9)),
        equals(ReliabilityLevel.moderate),
      );
    });

    test('returns poor for CV >= 50%', () {
      expect(
        reliabilityFromCV(const Percentage.fromPercent(50.0)),
        equals(ReliabilityLevel.poor),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(75.0)),
        equals(ReliabilityLevel.poor),
      );
      expect(
        reliabilityFromCV(const Percentage.fromPercent(100.0)),
        equals(ReliabilityLevel.poor),
      );
    });
  });

  group('integration: mean vs median with outliers', () {
    test('median is more robust to outliers than mean', () {
      // Simulate benchmark data with a GC pause outlier
      final normalSamples = [5.0, 5.1, 4.9, 5.0, 5.2, 4.8, 5.0, 5.1, 4.9];
      final withOutlier = [...normalSamples, 50.0]; // GC pause

      final normalMean = mean(normalSamples);
      final normalMedian = median(normalSamples);
      final outlierMean = mean(withOutlier);
      final outlierMedian = median(withOutlier);

      // Mean is significantly affected by outlier
      expect((outlierMean - normalMean).abs(), greaterThan(4.0));

      // Median is barely affected
      expect((outlierMedian - normalMedian).abs(), lessThan(0.2));
    });
  });
}
