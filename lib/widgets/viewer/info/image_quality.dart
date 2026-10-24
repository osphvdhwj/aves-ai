import 'dart:math';
import 'dart:typed_data';

/// Pure-Dart image-quality heuristics computed from decoded RGBA pixels.
///
/// All functions take a flat RGBA [Uint8List] with [width] × [height]
/// layout — the format produced by `ui.Image.toByteData(format: .rawRgba)`.
/// Down-sample to ~256px on the longest side before calling, so cost stays
/// bounded regardless of the source size.
class ImageQuality {
  /// Laplacian variance — larger means sharper.
  ///
  /// The image is convolved with the 3×3 Laplacian kernel
  /// `[[0,1,0],[1,-4,1],[0,1,0]]` over luma, and the variance of the
  /// result is returned. Typical thresholds: < 60 blurry, > 200 sharp.
  static double laplacianVariance(Uint8List rgba, int width, int height) {
    if (width < 3 || height < 3) return 0;

    final luma = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        // Rec. 709 luma coefficients
        final l = (0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2]).round();
        luma[y * width + x] = l.clamp(0, 255);
      }
    }

    double sum = 0;
    double sumSq = 0;
    var n = 0;
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final c = luma[y * width + x];
        final t = luma[(y - 1) * width + x];
        final b = luma[(y + 1) * width + x];
        final l = luma[y * width + x - 1];
        final r = luma[y * width + x + 1];
        final v = (t + b + l + r - 4 * c).toDouble();
        sum += v;
        sumSq += v * v;
        n++;
      }
    }
    if (n == 0) return 0;
    final mean = sum / n;
    return (sumSq / n) - (mean * mean);
  }

  /// Mean luma of the image, in `[0, 255]`.
  static double meanLuma(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0) return 0;
    var sum = 0.0;
    final n = width * height;
    for (var i = 0; i < n; i++) {
      final j = i * 4;
      sum += 0.2126 * rgba[j] + 0.7152 * rgba[j + 1] + 0.0722 * rgba[j + 2];
    }
    return sum / n;
  }

  /// Fraction of pixels darker than [threshold] (0-255). Useful for
  /// detecting near-black frames and underexposure.
  static double darkFraction(Uint8List rgba, int width, int height, {int threshold = 32}) {
    if (width <= 0 || height <= 0) return 0;
    var dark = 0;
    final n = width * height;
    for (var i = 0; i < n; i++) {
      final j = i * 4;
      final l = 0.2126 * rgba[j] + 0.7152 * rgba[j + 1] + 0.0722 * rgba[j + 2];
      if (l < threshold) dark++;
    }
    return dark / n;
  }

  /// Fraction of pixels brighter than [threshold] (0-255).
  static double brightFraction(Uint8List rgba, int width, int height, {int threshold = 240}) {
    if (width <= 0 || height <= 0) return 0;
    var bright = 0;
    final n = width * height;
    for (var i = 0; i < n; i++) {
      final j = i * 4;
      final l = 0.2126 * rgba[j] + 0.7152 * rgba[j + 1] + 0.0722 * rgba[j + 2];
      if (l > threshold) bright++;
    }
    return bright / n;
  }

  /// 8×8 average-luma perceptual hash. Two images with hamming distance
  /// <= 4 are near-duplicates. Returns a 64-bit value packed in an [int].
  static int perceptualHash(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0) return 0;
    const cells = 8;
    final cellW = max(1, width ~/ cells);
    final cellH = max(1, height ~/ cells);
    final means = List<double>.filled(cells * cells, 0);
    for (var cy = 0; cy < cells; cy++) {
      for (var cx = 0; cx < cells; cx++) {
        var sum = 0.0;
        var n = 0;
        for (var y = cy * cellH; y < (cy + 1) * cellH && y < height; y++) {
          for (var x = cx * cellW; x < (cx + 1) * cellW && x < width; x++) {
            final j = (y * width + x) * 4;
            sum += 0.2126 * rgba[j] + 0.7152 * rgba[j + 1] + 0.0722 * rgba[j + 2];
            n++;
          }
        }
        means[cy * cells + cx] = n > 0 ? sum / n : 0;
      }
    }
    final overall = means.reduce((a, b) => a + b) / means.length;
    var hash = 0;
    for (var i = 0; i < means.length; i++) {
      if (means[i] >= overall) hash |= 1 << i;
    }
    return hash;
  }

  /// Hamming distance between two [perceptualHash] values.
  static int hammingDistance(int a, int b) {
    var x = a ^ b;
    var count = 0;
    while (x != 0) {
      count += x & 1;
      x >>= 1;
    }
    return count;
  }
}
