# flutter_native_image_compress

Native image resize and compression for Flutter using platform APIs.

Supports Android, iOS, macOS, Windows, and Web.

## Features

- Resize to a max width/height while preserving aspect ratio
- If the image is smaller than max, only compression is applied
- JPEG quality control (0-100, default 70)
- PNG is lossless (quality ignored)
- Memory and file-path APIs
- Native implementations per platform (no Dart compression)

## Supported formats

- JPEG (lossy, quality control)
- PNG (lossless, quality ignored)
- WebP (lossy, quality control)

## Usage

Add the dependency:

```yaml
dependencies:
  flutter_native_image_compress: ^0.2.0
```

Import and compress in memory:

```dart
import 'dart:typed_data';
import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';

final Uint8List inputBytes = ...;
final options = const CompressOptions(
  maxWidth: 1024,
  maxHeight: 1024,
  quality: 70,
);

final Uint8List outputBytes =
    await FlutterNativeImageCompress.compress(inputBytes, options);
```

Compress from file path:

```dart
final options = const CompressOptions(maxWidth: 1200, quality: 70);
final Uint8List outputBytes =
    await FlutterNativeImageCompress.compressFile('/path/to/image.jpg', options);
```

## Error Handling

This plugin uses graceful error handling. If compression fails for any reason:
- The original image data is returned unchanged
- An error message is logged for debugging
- No exceptions are thrown to the caller
- Your application continues functioning normally

This ensures robust behavior even with corrupted or unsupported image data.

## Notes

- PNG is resized but not lossy compressed (lossless format).
- WebP and JPEG support quality control (0-100, default 70).
- Supported formats: JPEG, PNG, WebP.
- Compression failures return original data instead of throwing exceptions.

## Publishing

This repository includes a GitHub Actions workflow that publishes to pub.dev on tag pushes.
Tag format: `vX.Y.Z` (example: `v0.1.0`).
