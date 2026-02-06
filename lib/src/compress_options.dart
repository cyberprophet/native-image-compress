import 'package:meta/meta.dart';

/// Options for image compression.
///
/// Defines the maximum dimensions and quality for image compression.
/// - [maxWidth] and [maxHeight] are optional; if null, no dimension limit is applied.
/// - [quality] is clamped to the range 0-100 (default: 70).
///   - For JPEG: controls compression quality (0 = lowest, 100 = highest).
///   - For PNG: ignored (PNG is lossless, only resizing is applied).
@immutable
class CompressOptions {
  /// Maximum width in pixels. If null, width is unlimited.
  final int? maxWidth;

  /// Maximum height in pixels. If null, height is unlimited.
  final int? maxHeight;

  /// Compression quality (0-100). Default is 70.
  ///
  /// - JPEG: 0 = lowest quality, 100 = highest quality.
  /// - PNG: ignored (lossless format).
  final int quality;

  /// Creates compression options with optional dimension limits and quality.
  ///
  /// - [maxWidth]: Maximum width in pixels (null = unlimited). Negative values are clamped to null.
  /// - [maxHeight]: Maximum height in pixels (null = unlimited). Negative values are clamped to null.
  /// - [quality]: Compression quality (0-100, default: 70). Values outside this range are clamped.
  const CompressOptions({int? maxWidth, int? maxHeight, int quality = 70})
    : maxWidth = maxWidth != null && maxWidth < 0 ? null : maxWidth,
      maxHeight = maxHeight != null && maxHeight < 0 ? null : maxHeight,
      quality = quality < 0
          ? 0
          : quality > 100
          ? 100
          : quality;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompressOptions &&
          runtimeType == other.runtimeType &&
          maxWidth == other.maxWidth &&
          maxHeight == other.maxHeight &&
          quality == other.quality;

  @override
  int get hashCode => Object.hash(maxWidth, maxHeight, quality);

  @override
  String toString() =>
      'CompressOptions(maxWidth: $maxWidth, maxHeight: $maxHeight, quality: $quality)';
}
