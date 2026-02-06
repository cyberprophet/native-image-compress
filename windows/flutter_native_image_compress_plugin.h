#ifndef FLUTTER_PLUGIN_FLUTTER_NATIVE_IMAGE_COMPRESS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_NATIVE_IMAGE_COMPRESS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <vector>
#include <string>

struct IWICImagingFactory;
struct IWICBitmapSource;

namespace flutter_native_image_compress {

class FlutterNativeImageCompressPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterNativeImageCompressPlugin();

  virtual ~FlutterNativeImageCompressPlugin();

  // Disallow copy and assign.
  FlutterNativeImageCompressPlugin(const FlutterNativeImageCompressPlugin&) = delete;
  FlutterNativeImageCompressPlugin& operator=(const FlutterNativeImageCompressPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  std::vector<uint8_t> CompressImageData(
      const std::vector<uint8_t>& data,
      int maxWidth,
      int maxHeight,
      int quality);

  std::vector<uint8_t> CompressImageFile(
      const std::wstring& path,
      int maxWidth,
      int maxHeight,
      int quality);

  std::vector<uint8_t> CompressWithWIC(
      IWICImagingFactory* factory,
      IWICBitmapSource* source,
      const GUID& containerFormat,
      int maxWidth,
      int maxHeight,
      int quality);

  std::wstring Utf8ToWide(const std::string& utf8);
};

}  // namespace flutter_native_image_compress

#endif  // FLUTTER_PLUGIN_FLUTTER_NATIVE_IMAGE_COMPRESS_PLUGIN_H_
