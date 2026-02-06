import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_image_compress_platform_interface.dart';
import 'src/compress_options.dart';

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
        debugPrint(
          'Platform returned null result for compress, returning original data',
        );
        return data;
      }

      return result;
    } on PlatformException catch (e) {
      debugPrint(
        'Platform exception during compress: ${e.message} (${e.code})',
      );
      return data;
    } catch (e) {
      debugPrint('Unexpected error during compress: $e');
      return data;
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
        debugPrint(
          'Platform returned null result for compressFile, returning original file bytes',
        );
        return Uint8List(0);
      }

      return result;
    } on PlatformException catch (e) {
      debugPrint(
        'Platform exception during compressFile: ${e.message} (${e.code})',
      );
      return Uint8List(0);
    } catch (e) {
      debugPrint('Unexpected error during compressFile: $e');
      return Uint8List(0);
    }
  }
}
