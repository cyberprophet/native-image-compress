// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'flutter_native_image_compress_platform_interface.dart';
import 'src/compress_options.dart';
import 'src/image_compress_exception.dart';

/// A web implementation of the FlutterNativeImageCompressPlatform of the FlutterNativeImageCompress plugin.
class FlutterNativeImageCompressWeb extends FlutterNativeImageCompressPlatform {
  /// Constructs a FlutterNativeImageCompressWeb
  FlutterNativeImageCompressWeb();

  static void registerWith(Registrar registrar) {
    FlutterNativeImageCompressPlatform.instance =
        FlutterNativeImageCompressWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<Uint8List> compress(Uint8List data, CompressOptions options) async {
    try {
      // Detect image format by magic bytes
      final format = _detectFormat(data);
      final mimeType = format == 'jpeg' ? 'image/jpeg' : 'image/png';

      // Create blob from Uint8List
      final blob = web.Blob(
        [data.buffer.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      final url = web.URL.createObjectURL(blob);

      try {
        // Load image
        final img = web.HTMLImageElement();
        final completer = Completer<void>();

        img.addEventListener(
          'load',
          (web.Event event) {
            completer.complete();
          }.toJS,
        );

        img.addEventListener(
          'error',
          (web.Event event) {
            completer.completeError(
              ImageCompressException('Failed to load image', 'INVALID_IMAGE'),
            );
          }.toJS,
        );

        img.src = url;
        await completer.future;

        // Calculate target dimensions
        final dimensions = _calculateDimensions(
          img.width,
          img.height,
          options.maxWidth,
          options.maxHeight,
        );

        // Create canvas and draw resized image
        final canvas = web.HTMLCanvasElement();
        canvas.width = dimensions.width;
        canvas.height = dimensions.height;

        final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
        ctx.drawImage(
          img,
          0,
          0,
          dimensions.width.toDouble(),
          dimensions.height.toDouble(),
        );

        // Convert to blob
        final resultCompleter = Completer<Uint8List>();

        canvas.toBlob(
          ((web.Blob? blob) {
            if (blob == null) {
              resultCompleter.completeError(
                ImageCompressException(
                  'Failed to create blob',
                  'COMPRESSION_FAILED',
                ),
              );
              return;
            }

            final reader = web.FileReader();
            reader.addEventListener(
              'loadend',
              (web.Event event) {
                final result = reader.result;
                if (result != null) {
                  final jsArrayBuffer = result as JSArrayBuffer;
                  final uint8List = jsArrayBuffer.toDart.asUint8List();
                  resultCompleter.complete(uint8List);
                } else {
                  resultCompleter.completeError(
                    ImageCompressException(
                      'Failed to read blob',
                      'COMPRESSION_FAILED',
                    ),
                  );
                }
              }.toJS,
            );

            reader.addEventListener(
              'error',
              (web.Event event) {
                resultCompleter.completeError(
                  ImageCompressException(
                    'Failed to read blob',
                    'COMPRESSION_FAILED',
                  ),
                );
              }.toJS,
            );

            reader.readAsArrayBuffer(blob);
          }).toJS,
          mimeType,
          format == 'jpeg' ? (options.quality / 100.0).toJS : null,
        );

        return await resultCompleter.future;
      } finally {
        web.URL.revokeObjectURL(url);
      }
    } catch (e) {
      if (e is ImageCompressException) {
        rethrow;
      }
      throw ImageCompressException(
        'Unexpected error during compression: $e',
        'COMPRESSION_FAILED',
      );
    }
  }

  @override
  Future<Uint8List> compressFile(String path, CompressOptions options) async {
    throw ImageCompressException(
      'File compression is not supported on web platform. Use compress() with Uint8List data instead.',
      'UNSUPPORTED_OPERATION',
    );
  }

  /// Detects image format by magic bytes.
  /// Returns 'jpeg' or 'png'.
  String _detectFormat(Uint8List data) {
    if (data.length < 4) {
      throw ImageCompressException('Invalid image data', 'INVALID_IMAGE');
    }

    // JPEG magic bytes: FF D8
    if (data[0] == 0xFF && data[1] == 0xD8) {
      return 'jpeg';
    }

    // PNG magic bytes: 89 50 4E 47
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'png';
    }

    throw ImageCompressException(
      'Unsupported image format. Only JPEG and PNG are supported.',
      'UNSUPPORTED_FORMAT',
    );
  }

  /// Calculates target dimensions maintaining aspect ratio.
  ({int width, int height}) _calculateDimensions(
    int originalWidth,
    int originalHeight,
    int? maxWidth,
    int? maxHeight,
  ) {
    if (maxWidth == null && maxHeight == null) {
      return (width: originalWidth, height: originalHeight);
    }

    double scale = 1.0;

    if (maxWidth != null && originalWidth > maxWidth) {
      scale = maxWidth / originalWidth;
    }

    if (maxHeight != null && originalHeight > maxHeight) {
      final heightScale = maxHeight / originalHeight;
      if (heightScale < scale) {
        scale = heightScale;
      }
    }

    return (
      width: (originalWidth * scale).round(),
      height: (originalHeight * scale).round(),
    );
  }
}
