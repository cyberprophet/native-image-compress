import 'dart:io';
import 'dart:typed_data';

Future<String?> writeTempFile(Uint8List bytes, String name) async {
  final tempDir = await Directory.systemTemp.createTemp('compress_test');
  final file = File('${tempDir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
