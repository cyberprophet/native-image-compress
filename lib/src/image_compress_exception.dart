/// Exception thrown when image compression fails.
///
/// Contains a descriptive [message] and an optional error [code]
/// for programmatic error handling.
class ImageCompressException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// An optional error code for programmatic error handling.
  ///
  /// Common codes:
  /// - 'INVALID_IMAGE': The input data is not a valid image.
  /// - 'FILE_NOT_FOUND': The specified file path does not exist.
  /// - 'COMPRESSION_FAILED': The compression operation failed.
  /// - 'UNSUPPORTED_FORMAT': The image format is not supported.
  final String? code;

  /// Creates an image compression exception.
  ///
  /// - [message]: A human-readable error description.
  /// - [code]: An optional error code for programmatic handling.
  const ImageCompressException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'ImageCompressException($code): $message';
    }
    return 'ImageCompressException: $message';
  }
}
