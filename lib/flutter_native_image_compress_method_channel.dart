import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_image_compress_platform_interface.dart';
import 'src/compress_options.dart';
import 'src/image_compress_exception.dart';

/// An implementation of [FlutterNativeImageCompressPlatform] that uses method channels.
class MethodChannelFlutterNativeImageCompress
    extends FlutterNativeImageCompressPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_image_compress');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Uint8List> compress(Uint8List data, CompressOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<Uint8List>('compress', {
        'data': data,
        'maxWidth': options.maxWidth,
        'maxHeight': options.maxHeight,
        'quality': options.quality,
      });

      if (result == null) {
        throw ImageCompressException(
          'Platform returned null result',
          'COMPRESSION_FAILED',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw ImageCompressException(
        e.message ?? 'Image compression failed',
        e.code,
      );
    } catch (e) {
      throw ImageCompressException(
        'Unexpected error during compression: $e',
        'COMPRESSION_FAILED',
      );
    }
  }

  @override
  Future<Uint8List> compressFile(String path, CompressOptions options) async {
    try {
      final result = await methodChannel
          .invokeMethod<Uint8List>('compressFile', {
            'path': path,
            'maxWidth': options.maxWidth,
            'maxHeight': options.maxHeight,
            'quality': options.quality,
          });

      if (result == null) {
        throw ImageCompressException(
          'Platform returned null result',
          'COMPRESSION_FAILED',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw ImageCompressException(
        e.message ?? 'Image compression failed',
        e.code,
      );
    } catch (e) {
      throw ImageCompressException(
        'Unexpected error during compression: $e',
        'COMPRESSION_FAILED',
      );
    }
  }
}
