// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'dart:typed_data';

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
  ///
  /// Throws [ImageCompressException] if compression fails.
  static Future<Uint8List> compress(Uint8List data, CompressOptions options) {
    return FlutterNativeImageCompressPlatform.instance.compress(data, options);
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
  ///
  /// Throws [ImageCompressException] if the file is not found or compression fails.
  static Future<Uint8List> compressFile(String path, CompressOptions options) {
    return FlutterNativeImageCompressPlatform.instance.compressFile(
      path,
      options,
    );
  }
}
