# Benchmarking Guide

This guide explains the statistical foundations of benchmark_harness_plus and how to interpret its results correctly.

## The Problem with Naive Benchmarking

A naive benchmark might look like this:

```dart
final stopwatch = Stopwatch()..start();
myFunction();
stopwatch.stop();
print('Took ${stopwatch.elapsedMicroseconds} us');
```

This approach has serious problems:

1. **Single measurement**: One run tells you almost nothing. The next run might be 10x slower due to GC.
2. **No warmup**: The first run includes JIT compilation time, which is not representative.
3. **No context**: Is 500us good? Bad? You have no way to know without comparison.
4. **No reliability indicator**: You do not know if this measurement is stable or noisy.

benchmark_harness_plus addresses all of these issues.

## The Strategy

benchmark_harness_plus uses a multi-phase approach:

### Phase 1: Warmup

Before any measurements, each variant runs many times (default: 500 iterations). This allows:

- The Dart VM to JIT-compile hot paths
- CPU caches to warm up
- Any lazy initialization to complete

Warmup results are discarded entirely.

### Phase 2: Sampling

The benchmark collects multiple independent samples (default: 10). Each sample:

1. Optionally shuffles variant order (reduces systematic bias)
2. Triggers GC between variants (reduces GC interference)
3. Runs each variant many times (default: 1000 iterations)
4. Records the average time per operation

### Phase 3: Statistical Analysis

From the collected samples, the package computes:

- Central tendency: mean and median
- Dispersion: standard deviation, min, max
- Reliability: coefficient of variation (CV%)
- Comparisons: speedup ratios against baseline

## Understanding the Metrics

### Median

**What it is**: The middle value when all samples are sorted.

**How it is calculated**: Sort all samples, take the middle one. For even counts, average the two middle values.

**Benefits**:
- Ignores outliers completely
- Represents "typical" performance accurately
- Stable across runs even with occasional GC pauses
- The primary metric for comparing variants

**Downsides**:
- Discards information about the tails of the distribution
- Two distributions with very different shapes can have the same median
- Less mathematically tractable than mean

**Example**:
```
Samples: [5.0, 5.1, 4.9, 5.0, 50.0]  (one GC pause)
Median:  5.0 us  (correctly ignores the outlier)
```

### Mean (Average)

**What it is**: The sum of all values divided by the count.

**How it is calculated**: `sum(samples) / count(samples)`

**Benefits**:
- Uses all data points
- Mathematically well-understood
- Familiar to most people
- Useful for detecting outliers when compared with median

**Downsides**:
- Sensitive to outliers (a single GC pause can skew results significantly)
- Can misrepresent typical performance
- Not robust for benchmark data which commonly has outliers

**Example**:
```
Samples: [5.0, 5.1, 4.9, 5.0, 50.0]  (one GC pause)
Mean:    14.0 us  (heavily skewed by outlier)
```

**Interpreting mean vs median**:
- mean approximately equals median: Symmetric distribution, no significant outliers
- mean > median: High outliers present (common in benchmarks, caused by GC/OS)
- mean < median: Low outliers present (rare, might indicate measurement issues)

### Standard Deviation (stddev)

**What it is**: A measure of how spread out the samples are from the mean.

**How it is calculated**: Square root of variance, using Bessel's correction (n-1 denominator) for unbiased sample estimation.

```
variance = sum((sample - mean)^2) / (n - 1)
stddev = sqrt(variance)
```

**Benefits**:
- Quantifies measurement consistency
- In the same units as the measurement (microseconds)
- Well-understood statistical measure

**Downsides**:
- Based on mean, so affected by outliers
- Absolute value is hard to interpret without context
- A stddev of 1.0 means different things for a 10us vs 1000us measurement

**Example**:
```
Samples: [10.0, 10.1, 9.9, 10.0]
Stddev:  0.08 us  (very consistent)

Samples: [5.0, 15.0, 25.0, 35.0]
Stddev:  12.9 us  (high variance)
```

### Coefficient of Variation (CV%)

**What it is**: Standard deviation expressed as a percentage of the mean. Normalizes variance across different scales.

**How it is calculated**: `(stddev / mean) * 100`

**Benefits**:
- Scale-independent: Can compare reliability of 1us vs 1000us measurements
- Intuitive percentage interpretation
- Clear thresholds for reliability assessment
- The key metric for knowing if you can trust your results

**Downsides**:
- Undefined when mean is zero
- Can be misleading for measurements near zero
- Still based on mean/stddev, so affected by outliers

**Reliability thresholds**:

| CV%    | Level     | Meaning |
|--------|-----------|---------|
| < 10%  | Excellent | Highly reliable. Trust exact ratios and small differences. |
| 10-20% | Good      | Reliable. Rankings are trustworthy, ratios are approximate. |
| 20-50% | Moderate  | Directional only. Know which is faster, but not by how much. |
| > 50%  | Poor      | Unreliable. Measurement is dominated by noise. |

**Example**:
```
Measurement A: mean=100us, stddev=5us   -> CV=5%   (excellent)
Measurement B: mean=10us,  stddev=5us   -> CV=50%  (poor)
```

Both have the same absolute stddev, but A is far more reliable because the noise is small relative to the signal.

### Min and Max

**What they are**: The smallest and largest sample values.

**Benefits**:
- Shows the full range of observations
- Max can reveal worst-case performance
- Large max relative to median confirms presence of outliers

**Downsides**:
- Extremely sensitive to outliers (by definition)
- Single extreme values can be misleading
- Not useful for comparisons

**When to look at them**:
- To confirm outliers exist (max >> median)
- To understand worst-case scenarios
- To debug unexpectedly high variance

### Speedup Ratio (vs base)

**What it is**: How many times faster one variant is compared to the baseline.

**How it is calculated**: `baseline.median / variant.median`

**Benefits**:
- Intuitive interpretation: "2x faster" is clear
- Uses median, so robust against outliers
- Easy to compare across different benchmarks

**Downsides**:
- Requires choosing a baseline (first variant by default)
- Ratio of 1.05x might not be meaningful if CV% is high
- Does not indicate if the difference is statistically significant

**Interpreting ratios**:
- ratio > 1: Variant is faster than baseline
- ratio < 1: Variant is slower than baseline
- ratio = 1: Same performance

**Trust the ratio only if both variants have acceptable CV% (< 20%).**

## Reading the Output

Here is a complete example output with annotations:

```
[List Building] Warming up 3 variant(s)...
[List Building] Collecting 10 sample(s)...
[List Building] Done.

  Variant      |     median |       mean |   stddev |    cv% |  vs base
  -------------------------------------------------------------------
  growable     |       1.24 |       1.31 |     0.15 |   11.5 |        -
  fixed-length |       0.52 |       0.53 |     0.02 |    3.8 |    2.38x
  generate     |       0.89 |       0.91 |     0.04 |    4.4 |    1.39x

  (times in microseconds per operation)
```

**How to read this**:

1. **Check CV% first**: All variants have CV% < 20%, so measurements are reliable.

2. **Compare medians**:
   - fixed-length: 0.52us (fastest)
   - generate: 0.89us
   - growable: 1.24us (slowest)

3. **Check mean vs median**:
   - growable: mean (1.31) > median (1.24) suggests some high outliers
   - Others are close, indicating symmetric distributions

4. **Look at ratios**:
   - fixed-length is 2.38x faster than growable
   - generate is 1.39x faster than growable

5. **Conclusion**: fixed-length is the fastest approach, and you can trust this result.

## When Results Are Unreliable

If you see high CV% values:

```
  Variant      |     median |       mean |   stddev |    cv% |  vs base
  -------------------------------------------------------------------
  approach-a   |       0.08 |       0.12 |     0.09 |   75.0 |        -
  approach-b   |       0.06 |       0.09 |     0.07 |   77.8 |    1.33x

Note: The following measurements have CV% > 50% and may be unreliable:
  - approach-a (CV: 75.0%)
  - approach-b (CV: 77.8%)
```

**What this means**: The measurements are mostly noise. The 1.33x ratio is not meaningful.

**What to do**:
1. **Increase iterations**: Sub-microsecond operations need more iterations per sample
2. **Increase sample duration**: Each sample should take at least 10ms
3. **Check for interference**: Close other applications, disable CPU throttling
4. **Accept limitations**: Some operations are inherently noisy to measure

## Choosing Configuration

| Situation | Config | Why |
|-----------|--------|-----|
| Quick feedback during development | `BenchmarkConfig.quick` | Fast, approximate results |
| Normal benchmarking | `BenchmarkConfig.standard` | Good balance of speed and accuracy |
| Important decisions | `BenchmarkConfig.thorough` | Maximum statistical confidence |
| Very fast operations (< 1us) | Custom with high iterations | Need more iterations to overcome noise |
| Slow operations (> 10ms) | Custom with low iterations | Do not need many iterations |

**Custom configuration example**:

```dart
// For a function that takes ~100us
BenchmarkConfig(
  iterations: 100,       // 100 * 100us = 10ms per sample (good)
  samples: 20,           // More samples for confidence
  warmupIterations: 200, // Enough to trigger JIT
)

// For a function that takes ~0.1us
BenchmarkConfig(
  iterations: 100000,    // 100000 * 0.1us = 10ms per sample (good)
  samples: 10,           // Standard sample count
  warmupIterations: 10000,
)
```

## Summary: The Interpretation Checklist

When analyzing benchmark results:

1. **Is CV% acceptable?** (< 20% for reliable comparisons)
2. **What does median say?** (primary comparison metric)
3. **Does mean differ from median?** (indicates outliers if so)
4. **Are the ratios meaningful?** (only if CV% is acceptable for both variants)
5. **Is the difference large enough to matter?** (1.05x might not be worth optimizing for)

Remember: A benchmark that reports its own reliability (via CV%) is far more valuable than one that gives you a single number with false precision.
