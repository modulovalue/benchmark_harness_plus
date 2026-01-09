## 3.0.0

- **Breaking:** Added `Percentage` type for type-safe percentage values
- **Breaking:** `cv()` now returns `Percentage` instead of `double`
- **Breaking:** `BenchmarkResult.cv` now returns `Percentage`
- **Breaking:** `BenchmarkResult.improvementVs()` now returns `Percentage`
- **Breaking:** `BenchmarkComparison.improvementPercent` renamed to `improvement` and returns `Percentage`
- **Breaking:** `reliabilityFromCV()` now takes `Percentage` instead of `double`

## 2.0.0

- Bump SDK constraint to ^3.5.0
- Update extra_pedantic to ^5.0.0
- Add GitHub Actions CI

## 1.2.0

- Removed GC triggering between variants (can cause more noise than it reduces)

## 1.1.0

- Added "fastest" column to table output showing the minimum (best) sample time
- Added "Fastest" line to detailed result output
- Added new example demonstrating when minimum vs median should be used
- Restructured examples into separate files for easier reference

## 1.0.0

- Initial release
- Statistical functions: mean, median, stdDev, cv, min, max
- BenchmarkConfig with quick, standard, and thorough presets
- BenchmarkResult with computed statistics and reliability assessment
- BenchmarkComparison for comparing variants
- Benchmark harness with warmup and randomized ordering
- Result formatting: table, detailed, and CSV export
- Comprehensive documentation and examples
