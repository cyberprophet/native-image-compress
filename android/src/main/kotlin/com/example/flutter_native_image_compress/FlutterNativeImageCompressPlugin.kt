package com.example.flutter_native_image_compress

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File

/** FlutterNativeImageCompressPlugin */
class FlutterNativeImageCompressPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var backgroundHandler: Handler
    private lateinit var backgroundThread: HandlerThread
    private lateinit var mainHandler: Handler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_image_compress")
        channel.setMethodCallHandler(this)

        // Initialize background thread for compression work
        backgroundThread = HandlerThread("ImageCompressThread")
        backgroundThread.start()
        backgroundHandler = Handler(backgroundThread.looper)
        mainHandler = Handler(Looper.getMainLooper())
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "compress" -> {
                handleCompress(call, result)
            }
            "compressFile" -> {
                handleCompressFile(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleCompress(
        call: MethodCall,
        result: Result,
    ) {
        val data = call.argument<ByteArray>("data")
        val maxWidth = call.argument<Int>("maxWidth")
        val maxHeight = call.argument<Int>("maxHeight")
        val quality = call.argument<Int>("quality") ?: 70

        if (data == null) {
            result.error("INVALID_ARGUMENT", "data is required", null)
            return
        }

        backgroundHandler.post {
            try {
                val compressedData = compressImageData(data, maxWidth, maxHeight, quality)
                mainHandler.post {
                    result.success(compressedData)
                }
            } catch (e: Exception) {
                Log.e("ImageCompress", "Compression failed: ${e.message}. Returning original data.")
                mainHandler.post {
                    result.success(data)
                }
            }
        }
    }

    private fun handleCompressFile(
        call: MethodCall,
        result: Result,
    ) {
        val path = call.argument<String>("path")
        val maxWidth = call.argument<Int>("maxWidth")
        val maxHeight = call.argument<Int>("maxHeight")
        val quality = call.argument<Int>("quality") ?: 70

        if (path == null) {
            result.error("INVALID_ARGUMENT", "path is required", null)
            return
        }

        backgroundHandler.post {
            try {
                val compressedData = compressImageFile(path, maxWidth, maxHeight, quality)
                mainHandler.post {
                    result.success(compressedData)
                }
            } catch (e: Exception) {
                Log.e("ImageCompress", "Compression failed for file $path: ${e.message}. Attempting to return original data.")
                try {
                    val originalData = File(path).readBytes()
                    mainHandler.post {
                        result.success(originalData)
                    }
                } catch (fileReadError: Exception) {
                    Log.e("ImageCompress", "Failed to read original file $path: ${fileReadError.message}. Returning empty data.")
                    mainHandler.post {
                        result.success(ByteArray(0))
                    }
                }
            }
        }
    }

    private fun compressImageData(
        data: ByteArray,
        maxWidth: Int?,
        maxHeight: Int?,
        quality: Int,
    ): ByteArray {
        // Detect format from data
        val options =
            BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
        BitmapFactory.decodeByteArray(data, 0, data.size, options)

        val mimeType = options.outMimeType ?: detectMimeTypeFromMagicBytes(data)
        val compressFormat = resolveCompressFormat(mimeType)

        // Decode full bitmap
        val decodedBitmap =
            BitmapFactory.decodeByteArray(data, 0, data.size)
                ?: throw IllegalArgumentException("Failed to decode image data")

        return compressBitmap(decodedBitmap, maxWidth, maxHeight, quality, compressFormat)
    }

    private fun compressImageFile(
        path: String,
        maxWidth: Int?,
        maxHeight: Int?,
        quality: Int,
    ): ByteArray {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $path")
        }

        // Detect format from file
        val options =
            BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
        BitmapFactory.decodeFile(path, options)

        val mimeType = options.outMimeType ?: detectMimeTypeFromFile(file)
        val compressFormat = resolveCompressFormat(mimeType)

        // Decode full bitmap
        val decodedBitmap =
            BitmapFactory.decodeFile(path)
                ?: throw IllegalArgumentException("Failed to decode image file")

        return compressBitmap(decodedBitmap, maxWidth, maxHeight, quality, compressFormat)
    }

    private fun compressBitmap(
        bitmap: Bitmap,
        maxWidth: Int?,
        maxHeight: Int?,
        quality: Int,
        compressFormat: Bitmap.CompressFormat,
    ): ByteArray {
        var resultBitmap = bitmap

        try {
            // Calculate target dimensions maintaining aspect ratio
            if (maxWidth != null || maxHeight != null) {
                val targetDimensions =
                    calculateTargetDimensions(
                        bitmap.width,
                        bitmap.height,
                        maxWidth,
                        maxHeight,
                    )

                if (targetDimensions.first != bitmap.width || targetDimensions.second != bitmap.height) {
                    resultBitmap =
                        Bitmap.createScaledBitmap(
                            bitmap,
                            targetDimensions.first,
                            targetDimensions.second,
                            true, // filter for smooth scaling
                        )
                    // Only recycle original if we created a new bitmap
                    if (resultBitmap !== bitmap) {
                        bitmap.recycle()
                    }
                }
            }

            // Compress to output stream
            val outputStream = ByteArrayOutputStream()

            when (compressFormat) {
                Bitmap.CompressFormat.JPEG -> {
                    val clampedQuality = quality.coerceIn(0, 100)
                    resultBitmap.compress(Bitmap.CompressFormat.JPEG, clampedQuality, outputStream)
                }
                Bitmap.CompressFormat.WEBP_LOSSY -> {
                    val clampedQuality = quality.coerceIn(0, 100)
                    resultBitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, clampedQuality, outputStream)
                }
                Bitmap.CompressFormat.WEBP -> {
                    val clampedQuality = quality.coerceIn(0, 100)
                    resultBitmap.compress(Bitmap.CompressFormat.WEBP, clampedQuality, outputStream)
                }
                else -> {
                    resultBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                }
            }

            return outputStream.toByteArray()
        } finally {
            // Recycle bitmap if it's not the same as input (already recycled above)
            if (resultBitmap !== bitmap && !resultBitmap.isRecycled) {
                resultBitmap.recycle()
            }
        }
    }

    private fun calculateTargetDimensions(
        originalWidth: Int,
        originalHeight: Int,
        maxWidth: Int?,
        maxHeight: Int?,
    ): Pair<Int, Int> {
        var targetWidth = originalWidth
        var targetHeight = originalHeight

        // Calculate scale factors
        val widthScale =
            if (maxWidth != null && maxWidth > 0 && originalWidth > maxWidth) {
                maxWidth.toFloat() / originalWidth.toFloat()
            } else {
                1.0f
            }

        val heightScale =
            if (maxHeight != null && maxHeight > 0 && originalHeight > maxHeight) {
                maxHeight.toFloat() / originalHeight.toFloat()
            } else {
                1.0f
            }

        // Use the smaller scale to maintain aspect ratio
        val scale = minOf(widthScale, heightScale)

        if (scale < 1.0f) {
            targetWidth = (originalWidth * scale).toInt().coerceAtLeast(1)
            targetHeight = (originalHeight * scale).toInt().coerceAtLeast(1)
        }

        return Pair(targetWidth, targetHeight)
    }

    private fun resolveCompressFormat(mimeType: String?): Bitmap.CompressFormat {
        return when (mimeType) {
            "image/jpeg", "image/jpg" -> Bitmap.CompressFormat.JPEG
            "image/png" -> Bitmap.CompressFormat.PNG
            "image/webp" -> {
                // Use WEBP_LOSSY for API 30+, WEBP for older versions
                if (Build.VERSION.SDK_INT >= 30) {
                    Bitmap.CompressFormat.WEBP_LOSSY
                } else {
                    Bitmap.CompressFormat.WEBP
                }
            }
            else -> throw IllegalArgumentException(
                "Unsupported image format. Only JPEG, PNG, and WebP are supported.",
            )
        }
    }

    private fun detectMimeTypeFromMagicBytes(data: ByteArray): String? {
        if (data.size < 4) return null

        // JPEG: FF D8
        if (data[0] == 0xFF.toByte() && data[1] == 0xD8.toByte()) {
            return "image/jpeg"
        }

        // PNG: 89 50 4E 47
        if (data[0] == 0x89.toByte() &&
            data[1] == 0x50.toByte() &&
            data[2] == 0x4E.toByte() &&
            data[3] == 0x47.toByte()
        ) {
            return "image/png"
        }

        // WebP: 52 49 46 46 [4 bytes] 57 45 42 50 (RIFF....WEBP)
        if (data.size >= 12 &&
            data[0] == 0x52.toByte() &&
            data[1] == 0x49.toByte() &&
            data[2] == 0x46.toByte() &&
            data[3] == 0x46.toByte() &&
            data[8] == 0x57.toByte() &&
            data[9] == 0x45.toByte() &&
            data[10] == 0x42.toByte() &&
            data[11] == 0x50.toByte()
        ) {
            return "image/webp"
        }

        return null
    }

    private fun detectMimeTypeFromFile(file: File): String? {
        val bytes = ByteArray(4)
        file.inputStream().use { stream ->
            stream.read(bytes)
        }
        return detectMimeTypeFromMagicBytes(bytes)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        backgroundThread.quitSafely()
    }
}
