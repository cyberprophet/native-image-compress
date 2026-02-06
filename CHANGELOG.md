## 0.2.0

- **NEW**: WebP format support across all platforms (Android, iOS, macOS, Web)
  - WebP images can now be compressed with quality control (lossy compression)
  - Android: Uses WEBP_LOSSY on API 30+, WEBP on older versions
  - iOS/macOS: Uses NSBitmapImageRep with .webp representation
  - Web: Uses canvas.toBlob() with 'image/webp' mime type
- **IMPROVED**: Graceful error handling - compression failures now return original data instead of throwing exceptions
  - Errors are logged for debugging (debugPrint, NSLog, Log.e)
  - Applications continue functioning even if compression fails
  - Original image data is returned as fallback
- **UPDATED**: Supported formats now include JPEG, PNG, and WebP

## 0.1.1

- Remove internal project management files from repository.

## 0.1.0

- Initial release with native image resize/compression.
- Supports Android, iOS, macOS, Windows, and Web.
- JPEG quality control (default 70) and PNG lossless resize.
- Memory and file-path APIs.
