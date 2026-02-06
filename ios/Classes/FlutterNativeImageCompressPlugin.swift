import Flutter
import UIKit
import ImageIO

public class FlutterNativeImageCompressPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_image_compress", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeImageCompressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "compress":
      handleCompress(call: call, result: result)
    case "compressFile":
      handleCompressFile(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Compress from bytes
  private func handleCompress(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let data = args["data"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required 'data' argument", details: nil))
      return
    }
    
    let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue
    let maxHeight = (args["maxHeight"] as? NSNumber)?.intValue
    let quality = (args["quality"] as? NSNumber)?.intValue ?? 70
    
    let imageData = data.data
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let compressedData = try self.compressImageData(imageData, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality)
        DispatchQueue.main.async {
          result(FlutterStandardTypedData(bytes: compressedData))
        }
      } catch let error as CompressError {
        DispatchQueue.main.async {
          result(FlutterError(code: error.code, message: error.message, details: nil))
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  // MARK: - Compress from file
  private func handleCompressFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required 'path' argument", details: nil))
      return
    }
    
    let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue
    let maxHeight = (args["maxHeight"] as? NSNumber)?.intValue
    let quality = (args["quality"] as? NSNumber)?.intValue ?? 70
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let fileURL = URL(fileURLWithPath: path)
        let imageData = try Data(contentsOf: fileURL)
        
        let compressedData = try self.compressImageData(imageData, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality)
        DispatchQueue.main.async {
          result(FlutterStandardTypedData(bytes: compressedData))
        }
      } catch let error as CompressError {
        DispatchQueue.main.async {
          result(FlutterError(code: error.code, message: error.message, details: nil))
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  // MARK: - Core compression logic
  private func compressImageData(_ data: Data, maxWidth: Int?, maxHeight: Int?, quality: Int) throws -> Data {
    let format = try detectFormat(data)
    
    guard let image = UIImage(data: data) else {
      throw CompressError(code: "DECODE_FAILED", message: "Failed to decode image data")
    }
    
    let (targetWidth, targetHeight) = calculateTargetDimensions(
      originalWidth: Int(image.size.width),
      originalHeight: Int(image.size.height),
      maxWidth: maxWidth,
      maxHeight: maxHeight
    )
    
    let resizedImage: UIImage
    if targetWidth != Int(image.size.width) || targetHeight != Int(image.size.height) {
      resizedImage = resizeImage(image, to: CGSize(width: targetWidth, height: targetHeight))
    } else {
      resizedImage = image
    }
    
    let compressedData: Data?
    switch format {
    case .jpeg:
      compressedData = resizedImage.jpegData(compressionQuality: CGFloat(quality) / 100.0)
    case .png:
      compressedData = resizedImage.pngData()
    }
    
    guard let result = compressedData else {
      throw CompressError(code: "ENCODE_FAILED", message: "Failed to encode compressed image")
    }
    
    return result
  }

  // MARK: - Format detection
  private enum ImageFormat {
    case jpeg
    case png
  }

   private func detectFormat(_ data: Data) throws -> ImageFormat {
     return try detectFormatByMagicBytes(data)
   }

  private func detectFormatByMagicBytes(_ data: Data) throws -> ImageFormat {
    if data.count >= 4 {
      if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
        return .png
      }
      if data[0] == 0xFF && data[1] == 0xD8 {
        return .jpeg
      }
    }

    throw CompressError(
      code: "UNSUPPORTED_FORMAT",
      message: "Unsupported image format. Only JPEG and PNG are supported."
    )
  }

  // MARK: - Aspect ratio calculation
  private func calculateTargetDimensions(
    originalWidth: Int,
    originalHeight: Int,
    maxWidth: Int?,
    maxHeight: Int?
  ) -> (Int, Int) {
    var targetWidth = originalWidth
    var targetHeight = originalHeight
    
    guard maxWidth != nil || maxHeight != nil else {
      return (targetWidth, targetHeight)
    }
    
    let maxW = maxWidth ?? Int.max
    let maxH = maxHeight ?? Int.max
    
    let widthScale = maxW < targetWidth ? Double(maxW) / Double(targetWidth) : 1.0
    let heightScale = maxH < targetHeight ? Double(maxH) / Double(targetHeight) : 1.0
    let scale = min(widthScale, heightScale)
    
    if scale < 1.0 {
      targetWidth = Int(round(Double(targetWidth) * scale))
      targetHeight = Int(round(Double(targetHeight) * scale))
    }
    
    targetWidth = max(1, targetWidth)
    targetHeight = max(1, targetHeight)
    
    return (targetWidth, targetHeight)
  }

  // MARK: - Image resizing
  private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
}

// MARK: - Error type
private struct CompressError: Error {
  let code: String
  let message: String
}
