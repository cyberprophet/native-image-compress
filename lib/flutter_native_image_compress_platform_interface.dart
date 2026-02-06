import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_image_compress_method_channel.dart';
import 'src/compress_options.dart';

abstract class FlutterNativeImageCompressPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeImageCompressPlatform.
  FlutterNativeImageCompressPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeImageCompressPlatform _instance =
      MethodChannelFlutterNativeImageCompress();

  /// The default instance of [FlutterNativeImageCompressPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeImageCompress].
  static FlutterNativeImageCompressPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeImageCompressPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeImageCompressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Compresses image data in memory.
  ///
  /// Takes raw image [data] as [Uint8List] and applies compression according to [options].
  ///
  /// Returns compressed image data as [Uint8List].
  ///
  /// Throws [ImageCompressException] if compression fails.
  Future<Uint8List> compress(Uint8List data, CompressOptions options) {
    throw UnimplementedError('compress() has not been implemented.');
  }

  /// Compresses an image file from the filesystem.
  ///
  /// Takes a file [path] and applies compression according to [options].
  ///
  /// Returns compressed image data as [Uint8List].
  ///
  /// Throws [ImageCompressException] if the file is not found or compression fails.
  Future<Uint8List> compressFile(String path, CompressOptions options) {
    throw UnimplementedError('compressFile() has not been implemented.');
  }
}
