import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? _originalBytes;
  Uint8List? _compressedBytes;
  String? _filePath;
  bool _isBusy = false;
  String? _statusMessage;

  final TextEditingController _maxWidthController = TextEditingController();
  final TextEditingController _maxHeightController = TextEditingController();
  final TextEditingController _qualityController = TextEditingController(
    text: '70',
  );

  @override
  void dispose() {
    _maxWidthController.dispose();
    _maxHeightController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  int? _parseNullableInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  CompressOptions _buildOptions() {
    final maxWidth = _parseNullableInt(_maxWidthController.text);
    final maxHeight = _parseNullableInt(_maxHeightController.text);
    final quality = _parseNullableInt(_qualityController.text) ?? 70;

    return CompressOptions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _statusMessage = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      setState(() {
        _statusMessage = 'Failed to read image bytes.';
      });
      return;
    }

    setState(() {
      _originalBytes = file.bytes;
      _compressedBytes = null;
      _filePath = file.path;
      _statusMessage = null;
    });
  }

  Future<void> _compressInMemory() async {
    final bytes = _originalBytes;
    if (bytes == null) {
      setState(() {
        _statusMessage = 'Pick an image first.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      final options = _buildOptions();
      final result = await FlutterNativeImageCompress.compress(bytes, options);
      setState(() {
        _compressedBytes = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Compression failed: $e';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _compressFromFile() async {
    final path = _filePath;
    if (path == null || path.isEmpty) {
      setState(() {
        _statusMessage =
            'Selected file path is not available on this platform.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      final options = _buildOptions();
      final result = await FlutterNativeImageCompress.compressFile(
        path,
        options,
      );
      setState(() {
        _compressedBytes = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Compression failed: $e';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  String _formatBytes(Uint8List? bytes) {
    if (bytes == null) {
      return '-';
    }
    final kb = bytes.lengthInBytes / 1024.0;
    if (kb >= 1024) {
      final mb = kb / 1024.0;
      return '${mb.toStringAsFixed(2)} MB';
    }
    return '${kb.toStringAsFixed(1)} KB';
  }

  Widget _buildImageCard(String title, Uint8List? bytes) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(_formatBytes(bytes), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: bytes == null
                    ? const Text('No image')
                    : Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compression Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _maxWidthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Width',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _maxHeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Height',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _qualityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quality (0-100)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Image Compress Demo')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptionsForm(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isBusy ? null : _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pick Image'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isBusy ? null : _compressInMemory,
                      icon: const Icon(Icons.bolt_outlined),
                      label: const Text('Compress (Memory)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isBusy ? null : _compressFromFile,
                      icon: const Icon(Icons.folder_outlined),
                      label: const Text('Compress (File)'),
                    ),
                  ],
                ),
                if (_filePath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'File path: $_filePath',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildImageCard('Original', _originalBytes),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImageCard(
                              'Compressed',
                              _compressedBytes,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildImageCard('Original', _originalBytes),
                        const SizedBox(height: 12),
                        _buildImageCard('Compressed', _compressedBytes),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
