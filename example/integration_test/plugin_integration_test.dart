import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';
import 'file_io_stub.dart' if (dart.library.io) 'file_io_io.dart';

const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6VdCioAAAAASUVORK5CYII=';

const _jpegBase64 =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxISEhUTEhIVFhUVFRUVFRUVFRUVFRUWFhUXFhUYHSggGBolGxUVITEhJSkrLi4uFx8zODMtNygtLisBCgoKDg0OGxAQGzUmICU3LTctLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAAEAAQMBIgACEQEDEQH/xAAXAAEAAwAAAAAAAAAAAAAAAAAAAwQF/8QAFxEAAwEAAAAAAAAAAAAAAAAAAAERIf/aAAwDAQACEAMQAAAAj1X/AP/EABgQAQEAAwAAAAAAAAAAAAAAAAEAAhAR/9oACAEBAAEFAgVt4//EABQRAQAAAAAAAAAAAAAAAAAAABD/2gAIAQMBAT8BP//EABQRAQAAAAAAAAAAAAAAAAAAABD/2gAIAQIBAT8BP//EABgQAQEBAQEAAAAAAAAAAAAAAAERACEx/9oACAEBAAY/Ao6t/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyH/2gAMAwEAAgADAAAAED//xAAWEQADAAAAAAAAAAAAAAAAAAABEBH/2gAIAQMBAT8Qh//EABYRAQEBAAAAAAAAAAAAAAAAAAARIf/aAAgBAgEBPxCP/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compress PNG and JPEG in memory', (WidgetTester tester) async {
    final pngBytes = base64Decode(_pngBase64);
    final jpegBytes = base64Decode(_jpegBase64);

    final options = const CompressOptions(
      maxWidth: 512,
      maxHeight: 512,
      quality: 70,
    );

    final pngCompressed = await FlutterNativeImageCompress.compress(
      pngBytes,
      options,
    );
    final jpegCompressed = await FlutterNativeImageCompress.compress(
      jpegBytes,
      options,
    );

    expect(pngCompressed, isNotEmpty);
    expect(jpegCompressed, isNotEmpty);
  });

  testWidgets('compress JPEG from file (non-web only)', (
    WidgetTester tester,
  ) async {
    if (kIsWeb) {
      return;
    }

    final bytes = base64Decode(_jpegBase64);
    final path = await writeTempFile(bytes, 'test.jpg');
    if (path == null) {
      return;
    }

    final options = const CompressOptions(
      maxWidth: 256,
      maxHeight: 256,
      quality: 70,
    );
    final result = await FlutterNativeImageCompress.compressFile(path, options);

    expect(result, isNotEmpty);
  });
}
