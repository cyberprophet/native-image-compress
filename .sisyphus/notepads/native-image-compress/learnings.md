# Native Image Compress - Learnings

## Project Conventions

### Naming
- Package name: flutter_native_image_compress
- Dart class names: PascalCase
- File names: snake_case

### Architecture
- Federated plugin pattern (method channel)
- Platform interface: `FlutterNativeImageCompressPlatform`
- Method channel: `flutter_native_image_compress`

## Platform Configuration

### Supported Platforms
- Android: Kotlin + BitmapFactory/ImageDecoder
- iOS: Swift + UIKit/ImageIO
- macOS: Swift + AppKit/ImageIO
- Windows: C++ + WIC
- Web: Dart + Canvas API

### Min SDK Versions
- Android: Flutter default (21)
- iOS: Default
- macOS: Default
- Windows: Default
- Web: Modern browsers

## Compression Strategy

### JPEG
- Quality: 0-100 (default: 70)
- Format preservation

### PNG
- Lossless - only resizing, no quality adjustment
- Transparency preserved

## Parameter Validation
- Quality clamped: 0-100
- maxWidth/maxHeight: null allowed (unlimited)
- Negative values clamped to 0
- Values > 100 clamped to 100

## Error Handling
- Dart level: ImageCompressException
- Platform level: PlatformException
- All errors converted to ImageCompressException

## Example App
- Uses file_picker to support image selection across platforms
- Supports both in-memory and file-path compression flows

## API Layer Implementation

### CompressOptions Design
- Quality clamping: Uses ternary operator in initializer list (quality < 0 ? 0 : quality > 100 ? 100 : quality)
- Negative dimension handling: maxWidth/maxHeight < 0 → null (unlimited)
- Default quality: 70
- Immutable class with @immutable annotation from meta package

### Platform Interface Pattern
- Abstract methods in platform interface throw UnimplementedError
- Method channel implementation will override these methods
- Platform interface imports CompressOptions for type safety

### Public API Exports
- Main library file exports src/compress_options.dart and src/image_compress_exception.dart
- Static methods in FlutterNativeImageCompress delegate to platform instance
- Comprehensive dartdoc comments with usage examples

### Dependencies
- Added meta: ^1.17.0 for @immutable annotation
- plugin_platform_interface: ^2.0.2 (already present)

### Known Issues
- Web platform file has errors (missing flutter_web_plugins and web packages)
- These are pre-existing and will be addressed in platform implementation tasks

## Method Channel Implementation

### Method Channel Pattern
- Channel name: 'flutter_native_image_compress'
- Methods: compress(data, options), compressFile(path, options)
- Arguments format: Map with 'data'/'path', 'maxWidth', 'maxHeight', 'quality'
- PlatformException converted to ImageCompressException with code and message

### Error Handling
- Null result check: Throws ImageCompressException with 'COMPRESSION_FAILED' code
- PlatformException catch: Preserves error code and message
- Generic exception catch: Wraps in ImageCompressException

## Web Platform Implementation

### Dependencies
- flutter_web_plugins: sdk: flutter
- web: ^1.0.0
- dart:js_interop for .toJS conversions

### Web Compression Strategy
1. Detect format by magic bytes (JPEG: FFD8, PNG: 89504E47)
2. Create Blob from Uint8List.buffer.toJS
3. Create object URL from blob
4. Load image via HTMLImageElement with event listeners
5. Calculate dimensions maintaining aspect ratio
6. Draw to canvas with target dimensions
7. Convert canvas to blob with quality (JPEG only)
8. Read blob as ArrayBuffer via FileReader
9. Convert JSArrayBuffer to Uint8List

### Web API Patterns
- Event listeners: Use addEventListener() with .toJS callbacks
- Blob creation: [data.buffer.toJS].toJS for parts array
- Quality parameter: JPEG uses quality/100.0, PNG uses null
- Async operations: Use Completer for callback-based APIs
- Cleanup: Always revoke object URLs in finally block

### Web Limitations
- compressFile() not supported (throws UNSUPPORTED_OPERATION)
- Web can't access filesystem directly
- Users must use compress() with Uint8List data

### Magic Bytes Detection
- JPEG: 0xFF 0xD8
- PNG: 0x89 0x50 0x4E 0x47
- Minimum 4 bytes required for detection

### Aspect Ratio Calculation
- Calculate scale for width and height independently
- Use minimum scale to maintain aspect ratio
- Round final dimensions to integers

## macOS Platform Implementation

### NSImage/ImageIO Pattern
- Load with NSImage(data:) or NSImage(contentsOf:)
- Resize using NSImage lockFocus/draw/unlockFocus pattern
- Convert to NSBitmapImageRep via tiffRepresentation
- Compress with representation(using: .jpeg/.png, properties:)

### Background Execution
- DispatchQueue.global(qos: .userInitiated).async for work
- DispatchQueue.main.async for FlutterResult callback

### Format Detection
- Same magic bytes as other platforms
- PNG: 0x89 0x50 0x4E 0x47
- JPEG: 0xFF 0xD8

### Quality Handling
- JPEG: .compressionFactor property (0.0-1.0)
- PNG: No quality parameter (lossless)

## iOS Implementation

### Background Processing
- Use `DispatchQueue.global(qos: .userInitiated).async` for compression
- Return results on main thread with `DispatchQueue.main.async`
- All FlutterResult calls must be on main thread

### Format Detection
- Primary: CGImageSourceCopyTypeIdentifier from ImageIO framework
- Fallback: Magic bytes detection (JPEG: 0xFF 0xD8)
- Type identifiers: "public.jpeg", "public.jpg" for JPEG

### Image Resizing
- UIGraphicsImageRenderer is modern API (iOS 10+)
- Set format.scale = 1.0 for absolute pixel dimensions
- Use image.draw(in:) for aspect-ratio-correct drawing

### Compression
- JPEG: UIImage.jpegData(compressionQuality: CGFloat) - quality 0.0 to 1.0
- PNG: UIImage.pngData() - no quality parameter (lossless)

### Error Handling
- Custom CompressError struct conforming to Error protocol
- FlutterError(code:message:details:) for method channel errors
- INVALID_ARGUMENTS, DECODE_FAILED, ENCODE_FAILED, COMPRESSION_FAILED codes

## Windows Platform Implementation

### WIC (Windows Imaging Component) Pattern
- COM initialization with CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)
- IWICImagingFactory for all WIC operations
- IWICBitmapDecoder from stream (memory) or file
- Container format detection via GetContainerFormat()
- Fallback to magic bytes detection (JPEG: FFD8, PNG: 89504E47)

### RAII for COM
- Custom ComPtr<T> template for automatic COM Release()
- ComInitializer class handles CoInitializeEx/CoUninitialize lifecycle
- Handle S_FALSE and RPC_E_CHANGED_MODE as success cases

### Resize Pipeline
1. IWICBitmapDecoder → IWICBitmapFrameDecode
2. Calculate target dimensions maintaining aspect ratio
3. IWICBitmapScaler with WICBitmapInterpolationModeHighQualityCubic
4. IWICFormatConverter for pixel format compatibility

### Encoding with Quality
- JPEG: IPropertyBag2 with "ImageQuality" (VT_R4, 0.0-1.0)
- PNG: No quality parameter (lossless)
- Pixel formats: 24bppBGR for JPEG, 32bppBGRA for PNG (alpha support)

### Memory Streams
- CreateStreamOnHGlobal for in-memory compression
- Write input data, seek to start, decode
- Output to new stream, then read back to vector<uint8_t>

### Path Handling
- UTF-8 to UTF-16 conversion via MultiByteToWideChar(CP_UTF8)
- Use wstring for all Windows file paths

### Libraries
- windowscodecs.lib (WIC)
- shlwapi.lib (stream utilities)
- ole32.lib (COM)
