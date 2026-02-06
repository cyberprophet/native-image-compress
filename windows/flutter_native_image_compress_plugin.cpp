#include "flutter_native_image_compress_plugin.h"

#include <windows.h>
#include <wincodec.h>
#include <combaseapi.h>
#include <shlwapi.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <vector>
#include <string>
#include <stdexcept>

#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "ole32.lib")

namespace flutter_native_image_compress {

namespace {

class ComInitializer {
 public:
  ComInitializer() : initialized_(false) {
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    initialized_ = SUCCEEDED(hr) || hr == S_FALSE || hr == RPC_E_CHANGED_MODE;
  }
  ~ComInitializer() {
    if (initialized_) {
      CoUninitialize();
    }
  }
  bool IsInitialized() const { return initialized_; }
 private:
  bool initialized_;
};

template<typename T>
class ComPtr {
 public:
  ComPtr() : ptr_(nullptr) {}
  ~ComPtr() { Release(); }
  T** operator&() { return &ptr_; }
  T* operator->() { return ptr_; }
  T* Get() const { return ptr_; }
  void Release() {
    if (ptr_) {
      ptr_->Release();
      ptr_ = nullptr;
    }
  }
 private:
  T* ptr_;
};

bool DetectContainerFormat(const std::vector<uint8_t>& data, GUID* format) {
  if (data.size() >= 2 && data[0] == 0xFF && data[1] == 0xD8) {
    *format = GUID_ContainerFormatJpeg;
    return true;
  }
  if (data.size() >= 4 && data[0] == 0x89 && data[1] == 0x50 &&
      data[2] == 0x4E && data[3] == 0x47) {
    *format = GUID_ContainerFormatPng;
    return true;
  }
  return false;
}

bool IsSupportedContainerFormat(const GUID& format) {
  return IsEqualGUID(format, GUID_ContainerFormatJpeg) ||
         IsEqualGUID(format, GUID_ContainerFormatPng);
}

void CalculateTargetDimensions(UINT originalWidth, UINT originalHeight,
                               int maxWidth, int maxHeight,
                               UINT* targetWidth, UINT* targetHeight) {
  *targetWidth = originalWidth;
  *targetHeight = originalHeight;
  
  if (maxWidth <= 0 && maxHeight <= 0) {
    return;
  }
  
  double scaleX = (maxWidth > 0) ? static_cast<double>(maxWidth) / originalWidth : 1.0;
  double scaleY = (maxHeight > 0) ? static_cast<double>(maxHeight) / originalHeight : 1.0;
  double scale = (scaleX < scaleY) ? scaleX : scaleY;
  
  if (scale < 1.0) {
    *targetWidth = static_cast<UINT>(originalWidth * scale + 0.5);
    *targetHeight = static_cast<UINT>(originalHeight * scale + 0.5);
    if (*targetWidth < 1) *targetWidth = 1;
    if (*targetHeight < 1) *targetHeight = 1;
  }
}

}  // namespace

void FlutterNativeImageCompressPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_native_image_compress",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterNativeImageCompressPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterNativeImageCompressPlugin::FlutterNativeImageCompressPlugin() {}

FlutterNativeImageCompressPlugin::~FlutterNativeImageCompressPlugin() {}

void FlutterNativeImageCompressPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  
  if (method_call.method_name() == "compress") {
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
      return;
    }
    
    auto data_it = arguments->find(flutter::EncodableValue("data"));
    auto max_width_it = arguments->find(flutter::EncodableValue("maxWidth"));
    auto max_height_it = arguments->find(flutter::EncodableValue("maxHeight"));
    auto quality_it = arguments->find(flutter::EncodableValue("quality"));
    
    if (data_it == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing 'data' argument");
      return;
    }
    
    const auto* data = std::get_if<std::vector<uint8_t>>(&data_it->second);
    if (!data || data->empty()) {
      result->Error("INVALID_ARGUMENTS", "'data' must be a non-empty byte array");
      return;
    }
    
    int maxWidth = 0;
    int maxHeight = 0;
    int quality = 70;
    
    if (max_width_it != arguments->end() && !std::holds_alternative<std::monostate>(max_width_it->second)) {
      if (auto* val = std::get_if<int32_t>(&max_width_it->second)) {
        maxWidth = *val;
      }
    }
    if (max_height_it != arguments->end() && !std::holds_alternative<std::monostate>(max_height_it->second)) {
      if (auto* val = std::get_if<int32_t>(&max_height_it->second)) {
        maxHeight = *val;
      }
    }
    if (quality_it != arguments->end()) {
      if (auto* val = std::get_if<int32_t>(&quality_it->second)) {
        quality = *val;
        if (quality < 0) quality = 0;
        if (quality > 100) quality = 100;
      }
    }
    
    try {
      auto compressed = CompressImageData(*data, maxWidth, maxHeight, quality);
      result->Success(flutter::EncodableValue(compressed));
    } catch (const std::exception& e) {
      result->Error("COMPRESSION_FAILED", e.what());
    }
    
  } else if (method_call.method_name() == "compressFile") {
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
      return;
    }
    
    auto path_it = arguments->find(flutter::EncodableValue("path"));
    auto max_width_it = arguments->find(flutter::EncodableValue("maxWidth"));
    auto max_height_it = arguments->find(flutter::EncodableValue("maxHeight"));
    auto quality_it = arguments->find(flutter::EncodableValue("quality"));
    
    if (path_it == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing 'path' argument");
      return;
    }
    
    const auto* path = std::get_if<std::string>(&path_it->second);
    if (!path || path->empty()) {
      result->Error("INVALID_ARGUMENTS", "'path' must be a non-empty string");
      return;
    }
    
    int maxWidth = 0;
    int maxHeight = 0;
    int quality = 70;
    
    if (max_width_it != arguments->end() && !std::holds_alternative<std::monostate>(max_width_it->second)) {
      if (auto* val = std::get_if<int32_t>(&max_width_it->second)) {
        maxWidth = *val;
      }
    }
    if (max_height_it != arguments->end() && !std::holds_alternative<std::monostate>(max_height_it->second)) {
      if (auto* val = std::get_if<int32_t>(&max_height_it->second)) {
        maxHeight = *val;
      }
    }
    if (quality_it != arguments->end()) {
      if (auto* val = std::get_if<int32_t>(&quality_it->second)) {
        quality = *val;
        if (quality < 0) quality = 0;
        if (quality > 100) quality = 100;
      }
    }
    
    try {
      std::wstring widePath = Utf8ToWide(*path);
      auto compressed = CompressImageFile(widePath, maxWidth, maxHeight, quality);
      result->Success(flutter::EncodableValue(compressed));
    } catch (const std::exception& e) {
      result->Error("COMPRESSION_FAILED", e.what());
    }
    
  } else {
    result->NotImplemented();
  }
}

std::vector<uint8_t> FlutterNativeImageCompressPlugin::CompressImageData(
    const std::vector<uint8_t>& data,
    int maxWidth,
    int maxHeight,
    int quality) {
  
  ComInitializer comInit;
  if (!comInit.IsInitialized()) {
    throw std::runtime_error("Failed to initialize COM");
  }
  
  ComPtr<IWICImagingFactory> factory;
  HRESULT hr = CoCreateInstance(
      CLSID_WICImagingFactory,
      nullptr,
      CLSCTX_INPROC_SERVER,
      IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create WIC factory");
  }
  
  ComPtr<IStream> inputStream;
  hr = CreateStreamOnHGlobal(nullptr, TRUE, &inputStream);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create input stream");
  }
  
  ULONG written;
  hr = inputStream->Write(data.data(), static_cast<ULONG>(data.size()), &written);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to write to input stream");
  }
  
  LARGE_INTEGER seekPos = {0};
  inputStream->Seek(seekPos, STREAM_SEEK_SET, nullptr);
  
  ComPtr<IWICBitmapDecoder> decoder;
  hr = factory->CreateDecoderFromStream(
      inputStream.Get(),
      nullptr,
      WICDecodeMetadataCacheOnDemand,
      &decoder);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to decode image data");
  }
  
  GUID containerFormat;
  hr = decoder->GetContainerFormat(&containerFormat);
  if (FAILED(hr) || !IsSupportedContainerFormat(containerFormat)) {
    if (!DetectContainerFormat(data, &containerFormat)) {
      throw std::runtime_error("Unsupported image format. Only JPEG and PNG are supported.");
    }
  }
  if (!IsSupportedContainerFormat(containerFormat)) {
    throw std::runtime_error("Unsupported image format. Only JPEG and PNG are supported.");
  }
  
  ComPtr<IWICBitmapFrameDecode> frame;
  hr = decoder->GetFrame(0, &frame);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to get image frame");
  }
  
  return CompressWithWIC(factory.Get(), frame.Get(), containerFormat, maxWidth, maxHeight, quality);
}

std::vector<uint8_t> FlutterNativeImageCompressPlugin::CompressImageFile(
    const std::wstring& path,
    int maxWidth,
    int maxHeight,
    int quality) {
  
  ComInitializer comInit;
  if (!comInit.IsInitialized()) {
    throw std::runtime_error("Failed to initialize COM");
  }
  
  ComPtr<IWICImagingFactory> factory;
  HRESULT hr = CoCreateInstance(
      CLSID_WICImagingFactory,
      nullptr,
      CLSCTX_INPROC_SERVER,
      IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create WIC factory");
  }
  
  ComPtr<IWICBitmapDecoder> decoder;
  hr = factory->CreateDecoderFromFilename(
      path.c_str(),
      nullptr,
      GENERIC_READ,
      WICDecodeMetadataCacheOnDemand,
      &decoder);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to open image file");
  }
  
  GUID containerFormat;
  hr = decoder->GetContainerFormat(&containerFormat);
  if (FAILED(hr) || !IsSupportedContainerFormat(containerFormat)) {
    throw std::runtime_error("Unsupported image format. Only JPEG and PNG are supported.");
  }
  
  ComPtr<IWICBitmapFrameDecode> frame;
  hr = decoder->GetFrame(0, &frame);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to get image frame");
  }
  
  return CompressWithWIC(factory.Get(), frame.Get(), containerFormat, maxWidth, maxHeight, quality);
}

std::vector<uint8_t> FlutterNativeImageCompressPlugin::CompressWithWIC(
    IWICImagingFactory* factory,
    IWICBitmapSource* source,
    const GUID& containerFormat,
    int maxWidth,
    int maxHeight,
    int quality) {
  
  UINT originalWidth, originalHeight;
  HRESULT hr = source->GetSize(&originalWidth, &originalHeight);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to get image dimensions");
  }
  
  UINT targetWidth, targetHeight;
  CalculateTargetDimensions(originalWidth, originalHeight, maxWidth, maxHeight, &targetWidth, &targetHeight);
  
  IWICBitmapSource* finalSource = source;
  ComPtr<IWICBitmapScaler> scaler;
  
  if (targetWidth != originalWidth || targetHeight != originalHeight) {
    hr = factory->CreateBitmapScaler(&scaler);
    if (FAILED(hr)) {
      throw std::runtime_error("Failed to create bitmap scaler");
    }
    
    hr = scaler->Initialize(source, targetWidth, targetHeight, WICBitmapInterpolationModeHighQualityCubic);
    if (FAILED(hr)) {
      throw std::runtime_error("Failed to initialize scaler");
    }
    
    finalSource = scaler.Get();
  }
  
  ComPtr<IWICBitmapSource> convertedSource;
  WICPixelFormatGUID sourceFormat;
  hr = finalSource->GetPixelFormat(&sourceFormat);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to get pixel format");
  }
  
  if (!IsSupportedContainerFormat(containerFormat)) {
    throw std::runtime_error("Unsupported image format. Only JPEG and PNG are supported.");
  }
  bool isJpeg = IsEqualGUID(containerFormat, GUID_ContainerFormatJpeg);
  WICPixelFormatGUID targetFormat = isJpeg ? GUID_WICPixelFormat24bppBGR : GUID_WICPixelFormat32bppBGRA;
  
  if (!IsEqualGUID(sourceFormat, targetFormat)) {
    ComPtr<IWICFormatConverter> converter;
    hr = factory->CreateFormatConverter(&converter);
    if (FAILED(hr)) {
      throw std::runtime_error("Failed to create format converter");
    }
    
    hr = converter->Initialize(
        finalSource,
        targetFormat,
        WICBitmapDitherTypeNone,
        nullptr,
        0.0,
        WICBitmapPaletteTypeMedianCut);
    if (FAILED(hr)) {
      throw std::runtime_error("Failed to convert pixel format");
    }
    
    finalSource = converter.Get();
    convertedSource.Release();
    reinterpret_cast<IWICFormatConverter*>(finalSource)->AddRef();
  }
  
  ComPtr<IStream> outputStream;
  hr = CreateStreamOnHGlobal(nullptr, TRUE, &outputStream);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create output stream");
  }
  
  ComPtr<IWICBitmapEncoder> encoder;
  hr = factory->CreateEncoder(containerFormat, nullptr, &encoder);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create encoder");
  }
  
  hr = encoder->Initialize(outputStream.Get(), WICBitmapEncoderNoCache);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to initialize encoder");
  }
  
  ComPtr<IWICBitmapFrameEncode> frameEncode;
  ComPtr<IPropertyBag2> propertyBag;
  hr = encoder->CreateNewFrame(&frameEncode, &propertyBag);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create encoder frame");
  }
  
  if (isJpeg && propertyBag.Get()) {
    PROPBAG2 option = {0};
    option.pstrName = const_cast<LPOLESTR>(L"ImageQuality");
    VARIANT varValue;
    VariantInit(&varValue);
    varValue.vt = VT_R4;
    varValue.fltVal = static_cast<float>(quality) / 100.0f;
    propertyBag->Write(1, &option, &varValue);
  }
  
  hr = frameEncode->Initialize(propertyBag.Get());
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to initialize encoder frame");
  }
  
  hr = frameEncode->SetSize(targetWidth, targetHeight);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to set output size");
  }
  
  WICPixelFormatGUID pixelFormat = targetFormat;
  hr = frameEncode->SetPixelFormat(&pixelFormat);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to set pixel format");
  }
  
  hr = frameEncode->WriteSource(finalSource, nullptr);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to write image data");
  }
  
  hr = frameEncode->Commit();
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to commit frame");
  }
  
  hr = encoder->Commit();
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to commit encoder");
  }
  
  STATSTG stats;
  hr = outputStream->Stat(&stats, STATFLAG_NONAME);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to get output size");
  }
  
  LARGE_INTEGER seekPos = {0};
  outputStream->Seek(seekPos, STREAM_SEEK_SET, nullptr);
  
  std::vector<uint8_t> result(static_cast<size_t>(stats.cbSize.QuadPart));
  ULONG bytesRead;
  hr = outputStream->Read(result.data(), static_cast<ULONG>(result.size()), &bytesRead);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to read output data");
  }
  
  return result;
}

std::wstring FlutterNativeImageCompressPlugin::Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()), nullptr, 0);
  if (size <= 0) {
    throw std::runtime_error("Failed to convert path to wide string");
  }
  
  std::wstring wide(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()), &wide[0], size);
  return wide;
}

}  // namespace flutter_native_image_compress
