import 'dart:io';

import 'package:flutter/foundation.dart';

import 'flutter_native_image_compress_platform_interface.dart';
import 'src/compress_options.dart';

export 'src/compress_options.dart';
export 'src/image_compress_exception.dart';

/// Flutter Native Image Compress plugin.
///
/// Provides methods to compress images in memory or from files.
class FlutterNativeImageCompress {
  Future<String?> getPlatformVersion() {
    return FlutterNativeImageCompressPlatform.instance.getPlatformVersion();
  }

  /// Compresses image data in memory.
  ///
  /// Takes raw image [data] as [Uint8List] and applies compression according to [options].
  ///
  /// Example:
  /// ```dart
  /// final imageData = await File('image.jpg').readAsBytes();
  /// final compressed = await FlutterNativeImageCompress.compress(
  ///   imageData,
  ///   CompressOptions(maxWidth: 1024, maxHeight: 1024, quality: 85),
  /// );
  /// ```
  ///
  /// Returns compressed image data as [Uint8List].
  /// If compression fails, returns the original [data] unchanged.
  static Future<Uint8List> compress(
    Uint8List data,
    CompressOptions options,
  ) async {
    try {
      return await FlutterNativeImageCompressPlatform.instance.compress(
        data,
        options,
      );
    } catch (e) {
      debugPrint('Image compression failed: $e. Returning original data.');
      return data;
    }
  }

  /// Compresses an image file from the filesystem.
  ///
  /// Takes a file [path] and applies compression according to [options].
  ///
  /// Example:
  /// ```dart
  /// final compressed = await FlutterNativeImageCompress.compressFile(
  ///   '/path/to/image.jpg',
  ///   CompressOptions(maxWidth: 800, quality: 70),
  /// );
  /// ```
  ///
  /// Returns compressed image data as [Uint8List].
  /// If compression fails, returns the original file bytes unchanged.
  static Future<Uint8List> compressFile(
    String path,
    CompressOptions options,
  ) async {
    try {
      return await FlutterNativeImageCompressPlatform.instance.compressFile(
        path,
        options,
      );
    } catch (e) {
      debugPrint(
        'File compression failed for $path: $e. Returning original file bytes.',
      );
      try {
        final file = File(path);
        return await file.readAsBytes();
      } catch (fileError) {
        debugPrint('Failed to read original file: $fileError');
        return Uint8List(0);
      }
    }
  }
}
