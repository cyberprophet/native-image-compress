#include "include/flutter_native_image_compress/flutter_native_image_compress_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_native_image_compress_plugin.h"

void FlutterNativeImageCompressPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_native_image_compress::FlutterNativeImageCompressPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
