/// Utilities for formatting and printing benchmark results.
library;

import 'dart:math' as math;

import 'result.dart';
import 'statistics.dart';

/// Formats benchmark results as a table string.
///
/// Creates a formatted table showing all statistical measures for
/// each variant, with optional comparison ratios against a baseline.
///
/// [results] - The benchmark results to format.
/// [baselineName] - Name of the variant to use as baseline for ratios.
///   If null, the first result is used as baseline.
///
/// Returns a multi-line string suitable for console output.
///
/// Example output:
/// ```
/// Variant        |     median |       mean |   stddev |    cv% |  vs base
/// -----------------------------------------------------------------------
/// baseline       |      34.39 |      34.30 |     0.25 |    0.7 |        -
/// optimized      |      24.15 |      24.22 |     0.18 |    0.7 |    1.42x
/// ```
String formatResults(List<BenchmarkResult> results, {String? baselineName}) {
  if (results.isEmpty) return '(no results)';

  final baseline = baselineName != null
      ? results.firstWhere(
          (r) => r.name == baselineName,
          orElse: () => results.first,
        )
      : results.first;

  final nameWidth = results.map((r) => r.name.length).reduce(math.max);
  final buffer = StringBuffer();

  // Header
  buffer.writeln();
  buffer.writeln(
    '  ${'Variant'.padRight(nameWidth)} | '
    '${'median'.padLeft(10)} | '
    '${'mean'.padLeft(10)} | '
    '${'stddev'.padLeft(8)} | '
    '${'cv%'.padLeft(6)} | '
    '${'vs base'.padLeft(8)}',
  );
  buffer.writeln('  ${'-' * (nameWidth + 55)}');

  // Rows
  for (final r in results) {
    final ratio = baseline.median / r.median;
    final ratioStr = r == baseline ? '-' : '${ratio.toStringAsFixed(2)}x';

    buffer.writeln(
      '  ${r.name.padRight(nameWidth)} | '
      '${r.median.toStringAsFixed(2).padLeft(10)} | '
      '${r.mean.toStringAsFixed(2).padLeft(10)} | '
      '${r.stdDev.toStringAsFixed(2).padLeft(8)} | '
      '${r.cv.toStringAsFixed(1).padLeft(6)} | '
      '${ratioStr.padLeft(8)}',
    );
  }

  buffer.writeln();
  buffer.writeln('  (times in microseconds per operation)');

  return buffer.toString();
}

/// Prints benchmark results to the console.
///
/// Convenience wrapper around [formatResults] that prints directly.
///
/// [results] - The benchmark results to print.
/// [baselineName] - Name of the variant to use as baseline for ratios.
///
/// Example:
/// ```dart
/// final results = benchmark.run(log: print);
/// printResults(results, baselineName: 'baseline');
/// ```
void printResults(List<BenchmarkResult> results, {String? baselineName}) {
  print(formatResults(results, baselineName: baselineName));
}

/// Formats a detailed report for a single benchmark result.
///
/// Includes all statistics, reliability assessment, and interpretation
/// guidance.
///
/// Example output:
/// ```
/// Result: optimized
///   Samples: 10
///   Median:  24.15 us/op
///   Mean:    24.22 us/op
///   Stddev:  0.18 us
///   CV%:     0.7%
///   Range:   23.89 - 24.61 us
///   Reliability: excellent
/// ```
String formatDetailedResult(BenchmarkResult result) {
  final buffer = StringBuffer();

  buffer.writeln('Result: ${result.name}');
  buffer.writeln('  Samples: ${result.samples.length}');
  buffer.writeln('  Median:  ${result.median.toStringAsFixed(2)} us/op');
  buffer.writeln('  Mean:    ${result.mean.toStringAsFixed(2)} us/op');
  buffer.writeln('  Stddev:  ${result.stdDev.toStringAsFixed(2)} us');
  buffer.writeln('  CV%:     ${result.cv.toStringAsFixed(1)}%');
  buffer.writeln(
    '  Range:   ${result.min.toStringAsFixed(2)} - ${result.max.toStringAsFixed(2)} us',
  );
  buffer.writeln('  Reliability: ${result.reliability.name}');

  // Add interpretation
  final meanMedianDiff = result.mean - result.median;
  if (meanMedianDiff.abs() > result.stdDev) {
    if (meanMedianDiff > 0) {
      buffer.writeln(
        '  Note: mean > median suggests high outliers (normal for benchmarks)',
      );
    } else {
      buffer.writeln(
        '  Note: mean < median suggests low outliers (unusual)',
      );
    }
  }

  return buffer.toString();
}

/// Formats a comparison between two results.
///
/// Example output:
/// ```
/// Comparison: optimized vs baseline
///   Speedup:     1.42x faster
///   Improvement: 29.7%
///   Reliable:    yes
/// ```
String formatComparison(BenchmarkComparison comparison) {
  final buffer = StringBuffer();

  buffer.writeln(
    'Comparison: ${comparison.test.name} vs ${comparison.baseline.name}',
  );

  final speedup = comparison.speedup;
  if (speedup >= 1) {
    buffer.writeln('  Speedup:     ${speedup.toStringAsFixed(2)}x faster');
  } else {
    buffer.writeln(
      '  Slowdown:    ${(1 / speedup).toStringAsFixed(2)}x slower',
    );
  }

  final improvement = comparison.improvementPercent;
  if (improvement >= 0) {
    buffer.writeln('  Improvement: ${improvement.toStringAsFixed(1)}%');
  } else {
    buffer.writeln('  Regression:  ${(-improvement).toStringAsFixed(1)}%');
  }

  buffer.writeln('  Reliable:    ${comparison.isReliable ? 'yes' : 'no'}');

  if (!comparison.isReliable) {
    buffer.writeln(
      '  Warning: High variance in measurements. Treat as directional only.',
    );
  }

  return buffer.toString();
}

/// Formats results as CSV for export or further analysis.
///
/// Headers: name,median,mean,stddev,cv,min,max,samples...
///
/// Example:
/// ```dart
/// final csv = formatResultsAsCsv(results);
/// File('results.csv').writeAsStringSync(csv);
/// ```
String formatResultsAsCsv(List<BenchmarkResult> results) {
  final buffer = StringBuffer();

  // Find max samples for header
  final maxSamples =
      results.map((r) => r.samples.length).reduce(math.max);

  // Header
  buffer.write('name,median,mean,stddev,cv,min,max');
  for (var i = 0; i < maxSamples; i++) {
    buffer.write(',sample_$i');
  }
  buffer.writeln();

  // Rows
  for (final r in results) {
    buffer.write('${r.name},');
    buffer.write('${r.median},');
    buffer.write('${r.mean},');
    buffer.write('${r.stdDev},');
    buffer.write('${r.cv},');
    buffer.write('${r.min},');
    buffer.write('${r.max}');
    for (final sample in r.samples) {
      buffer.write(',$sample');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

/// Prints a reliability warning if any result has poor reliability.
///
/// Returns true if a warning was printed.
bool printReliabilityWarning(List<BenchmarkResult> results) {
  final poorResults = results.where(
    (r) => r.reliability == ReliabilityLevel.poor,
  );

  if (poorResults.isNotEmpty) {
    print('\nWarning: The following measurements have CV% > 50% '
        'and may be unreliable:');
    for (final r in poorResults) {
      print('  - ${r.name} (CV: ${r.cv.toStringAsFixed(1)}%)');
    }
    print('Consider increasing iterations or investigating system noise.\n');
    return true;
  }

  final moderateResults = results.where(
    (r) => r.reliability == ReliabilityLevel.moderate,
  );

  if (moderateResults.isNotEmpty) {
    print('\nNote: The following measurements have CV% 20-50% '
        '(directional only):');
    for (final r in moderateResults) {
      print('  - ${r.name} (CV: ${r.cv.toStringAsFixed(1)}%)');
    }
    print('');
    return true;
  }

  return false;
}
