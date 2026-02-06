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

- JPEG
- PNG

## Usage

Add the dependency:

```yaml
dependencies:
  flutter_native_image_compress: ^0.1.0
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

## Notes

- PNG is resized but not lossy compressed.
- Only JPEG and PNG are supported.
- Exceptions are thrown on invalid input or unsupported formats.

## Publishing

This repository includes a GitHub Actions workflow that publishes to pub.dev on tag pushes.
Tag format: `vX.Y.Z` (example: `v0.1.0`).
