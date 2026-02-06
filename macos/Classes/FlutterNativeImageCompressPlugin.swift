import Cocoa
import FlutterMacOS
import ImageIO

public class FlutterNativeImageCompressPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_native_image_compress", binaryMessenger: registrar.messenger)
        let instance = FlutterNativeImageCompressPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "compress":
            handleCompress(call: call, result: result)
        case "compressFile":
            handleCompressFile(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Compress
    
    private func handleCompress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let typedData = args["data"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing data argument", details: nil))
            return
        }
        
        let data = typedData.data
        let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue
        let maxHeight = (args["maxHeight"] as? NSNumber)?.intValue
        let quality = (args["quality"] as? NSNumber)?.intValue ?? 70
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let compressedData = try self.compressImageData(
                    data: data,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                    quality: quality
                )
                DispatchQueue.main.async {
                    result(FlutterStandardTypedData(bytes: compressedData))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - CompressFile
    
    private func handleCompressFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing path argument", details: nil))
            return
        }
        
        let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue
        let maxHeight = (args["maxHeight"] as? NSNumber)?.intValue
        let quality = (args["quality"] as? NSNumber)?.intValue ?? 70
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let compressedData = try self.compressImageFile(
                    path: path,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                    quality: quality
                )
                DispatchQueue.main.async {
                    result(FlutterStandardTypedData(bytes: compressedData))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Compression Core
    
    private func compressImageData(data: Data, maxWidth: Int?, maxHeight: Int?, quality: Int) throws -> Data {
        guard let image = NSImage(data: data) else {
            throw ImageCompressError.invalidImageData
        }
        
        let format = try detectImageFormat(data: data)
        return try compressImage(image: image, format: format, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality)
    }
    
    private func compressImageFile(path: String, maxWidth: Int?, maxHeight: Int?, quality: Int) throws -> Data {
        let url = URL(fileURLWithPath: path)
        
        guard let image = NSImage(contentsOf: url) else {
            throw ImageCompressError.invalidImageFile
        }
        
        guard let data = try? Data(contentsOf: url) else {
            throw ImageCompressError.fileReadError
        }
        
        let format = try detectImageFormat(data: data)
        return try compressImage(image: image, format: format, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality)
    }
    
    private func compressImage(image: NSImage, format: ImageFormat, maxWidth: Int?, maxHeight: Int?, quality: Int) throws -> Data {
        let originalSize = image.size
        let targetSize = calculateTargetSize(
            originalWidth: Int(originalSize.width),
            originalHeight: Int(originalSize.height),
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
        
        let resizedImage = resizeImage(image: image, targetSize: targetSize)
        
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ImageCompressError.bitmapCreationFailed
        }
        
        let compressedData: Data?
        switch format {
        case .jpeg:
            let compressionFactor = CGFloat(quality) / 100.0
            compressedData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
        case .png:
            compressedData = bitmap.representation(using: .png, properties: [:])
        }
        
        guard let result = compressedData else {
            throw ImageCompressError.compressionFailed
        }
        
        return result
    }
    
    // MARK: - Format Detection
    
    private func detectImageFormat(data: Data) throws -> ImageFormat {
        guard data.count >= 4 else {
            throw ImageCompressError.unsupportedFormat
        }

        let bytes = [UInt8](data.prefix(4))

        // PNG magic bytes: 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return .png
        }

        // JPEG magic bytes: FF D8
        if bytes[0] == 0xFF && bytes[1] == 0xD8 {
            return .jpeg
        }

        throw ImageCompressError.unsupportedFormat
    }
    
    // MARK: - Dimension Calculation
    
    private func calculateTargetSize(originalWidth: Int, originalHeight: Int, maxWidth: Int?, maxHeight: Int?) -> NSSize {
        var targetWidth = CGFloat(originalWidth)
        var targetHeight = CGFloat(originalHeight)
        
        guard maxWidth != nil || maxHeight != nil else {
            return NSSize(width: targetWidth, height: targetHeight)
        }
        
        let widthRatio = maxWidth != nil ? CGFloat(maxWidth!) / targetWidth : CGFloat.greatestFiniteMagnitude
        let heightRatio = maxHeight != nil ? CGFloat(maxHeight!) / targetHeight : CGFloat.greatestFiniteMagnitude
        
        let scale = min(widthRatio, heightRatio, 1.0)
        
        targetWidth = round(targetWidth * scale)
        targetHeight = round(targetHeight * scale)
        
        return NSSize(width: targetWidth, height: targetHeight)
    }
    
    // MARK: - Image Resizing
    
    private func resizeImage(image: NSImage, targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        
        newImage.unlockFocus()
        return newImage
    }
}

// MARK: - Supporting Types

private enum ImageFormat {
    case jpeg
    case png
}

private enum ImageCompressError: Error, LocalizedError {
    case invalidImageData
    case invalidImageFile
    case fileReadError
    case bitmapCreationFailed
    case compressionFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Unable to decode image data"
        case .invalidImageFile:
            return "Unable to load image from file"
        case .fileReadError:
            return "Unable to read file"
        case .bitmapCreationFailed:
            return "Unable to create bitmap representation"
        case .compressionFailed:
            return "Image compression failed"
        case .unsupportedFormat:
            return "Unsupported image format. Only JPEG and PNG are supported."
        }
    }
}
