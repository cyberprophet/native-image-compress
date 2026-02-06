import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';
import 'package:flutter_native_image_compress/flutter_native_image_compress_platform_interface.dart';
import 'package:flutter_native_image_compress/flutter_native_image_compress_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNativeImageCompressPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeImageCompressPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List> compress(Uint8List data, CompressOptions options) async {
    return Uint8List.fromList([...data, 0x00]);
  }

  @override
  Future<Uint8List> compressFile(String path, CompressOptions options) async {
    return Uint8List.fromList([0x01, 0x02, 0x03]);
  }
}

void main() {
  final FlutterNativeImageCompressPlatform initialPlatform =
      FlutterNativeImageCompressPlatform.instance;

  test('$MethodChannelFlutterNativeImageCompress is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterNativeImageCompress>(),
    );
  });

  test('getPlatformVersion', () async {
    FlutterNativeImageCompress flutterNativeImageCompressPlugin =
        FlutterNativeImageCompress();
    MockFlutterNativeImageCompressPlatform fakePlatform =
        MockFlutterNativeImageCompressPlatform();
    FlutterNativeImageCompressPlatform.instance = fakePlatform;

    expect(await flutterNativeImageCompressPlugin.getPlatformVersion(), '42');
  });

  test('compress delegates to platform', () async {
    FlutterNativeImageCompressPlatform.instance =
        MockFlutterNativeImageCompressPlatform();

    final input = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
    final result = await FlutterNativeImageCompress.compress(
      input,
      const CompressOptions(),
    );

    expect(result.length, input.length + 1);
  });

  test('compressFile delegates to platform', () async {
    FlutterNativeImageCompressPlatform.instance =
        MockFlutterNativeImageCompressPlatform();

    final result = await FlutterNativeImageCompress.compressFile(
      '/tmp/test.jpg',
      const CompressOptions(),
    );

    expect(result, isNotEmpty);
  });
}
