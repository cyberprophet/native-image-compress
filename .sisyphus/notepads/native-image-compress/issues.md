# Native Image Compress - Issues & Gotchas

## Known Issues

### Current State
- pubspec.yaml has placeholder platform configuration
- Web plugin has broken imports (flutter_web_plugins, web packages missing)
- Windows plugin has compilation errors (flutter headers)
- All native implementations are boilerplate only

## Potential Pitfalls

### Cross-Platform
1. **iOS/macOS code sharing temptation** - MUST NOT share code between platforms
2. **Threading** - Must use background threads for image processing on all platforms
3. **Memory management** - Large images can cause OOM

### Format Detection
- Must detect format by magic bytes, not extension
- JPEG: FFD8
- PNG: 89504E47

### Web Specific
- Canvas API is main-thread only
- CORS restrictions on external images
- No EXIF orientation data

### Windows Specific
- UTF-16 encoding for file paths (Korean characters)
- COM initialization required
- WIC is built-in, no external deps

### Android Specific
- API 21-27: BitmapFactory only
- API 28+: Can use ImageDecoder
- Memory constraints on older devices

## Testing Notes
- Platform builds must pass before considering complete
- Integration tests need actual image files
- Mock platform for unit tests

## Build Environment Issues

### iOS Build on Linux (2026-02-06)
- Cannot run `flutter build ios` on Linux - requires macOS with Xcode
- Swift LSP (sourcekit-lsp) not available on Linux for syntax validation
- iOS implementation completed but requires macOS verification
- Implementation follows all requirements: DispatchQueue.global, UIGraphicsImageRenderer, CGImageSourceCopyTypeIdentifier for format detection

## Build Verification Limitation

### Windows Build on Linux
- `flutter build windows` only works on Windows hosts
- Cannot verify Windows build from Linux development environment
- Implementation follows WIC best practices and should compile on Windows
- May need cross-platform CI/CD for full verification

## Tooling Constraints (2026-02-06)

### LSP Servers Missing
- kotlin-lsp not installed (cannot run lsp_diagnostics on .kt)
- sourcekit-lsp not installed (cannot run lsp_diagnostics on .swift)
- clangd not installed (cannot run lsp_diagnostics on .cpp)

### CLI Tools
- `rg` (ripgrep) not installed in environment

## Status Updates
- pubspec.yaml platform configuration fixed (placeholder removed)
- web dependencies added (flutter_web_plugins, web)
- native implementations are no longer boilerplate (Android/iOS/macOS/Windows)
