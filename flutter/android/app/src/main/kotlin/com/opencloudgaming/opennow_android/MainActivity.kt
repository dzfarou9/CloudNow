package com.opencloudgaming.opennow_android

import android.content.Intent
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var streamTextureId: Long = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, OpenNowChannels.CORE).setMethodCallHandler { call, result ->
            when (call.method) {
                "request" -> {
                    val request = call.argument<String>("request")
                    if (request == null) {
                        result.error("BAD_REQUEST", "Missing request JSON", null)
                    } else {
                        try {
                            result.success(OpenNowNative.coreRequest(request))
                        } catch (error: Throwable) {
                            result.error("CORE_ERROR", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, OpenNowChannels.CORE_EVENTS).setStreamHandler(CoreEventStreamHandler)

        MethodChannel(messenger, OpenNowChannels.STREAM).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "createTexture" -> {
                        // A Flutter-owned SurfaceTexture: the decoder writes straight
                        // into it and Flutter composites it without a CPU frame copy.
                        val entry = flutterEngine.textureRegistry.createSurfaceTexture()
                        streamTextureId = entry.id()
                        OpenNowNative.surfaceReady(Surface(entry.surfaceTexture()))
                        result.success(streamTextureId)
                    }
                    "releaseTexture" -> {
                        OpenNowNative.surfaceReleased()
                        flutterEngine.textureRegistry.releaseTexture(streamTextureId)
                        streamTextureId = -1
                        result.success(null)
                    }
                    "start" -> {
                        val config = call.argument<String>("config")
                            ?: throw IllegalArgumentException("Missing stream config")
                        startForegroundService(Intent(this, StreamForegroundService::class.java))
                        OpenNowNative.streamStart(config)
                        result.success(null)
                    }
                    "stop" -> {
                        OpenNowNative.streamStop()
                        stopService(Intent(this, StreamForegroundService::class.java))
                        result.success(null)
                    }
                    "submitKey" -> {
                        OpenNowNative.submitKey(
                            call.argument<Int>("keyCode") ?: 0,
                            call.argument<Int>("action") ?: 0,
                            call.argument<Int>("modifiers") ?: 0,
                        )
                        result.success(null)
                    }
                    "submitText" -> {
                        OpenNowNative.submitText(call.argument<String>("text") ?: "")
                        result.success(null)
                    }
                    "submitMouse" -> {
                        OpenNowNative.submitMouse(
                            call.argument<Float>("dx") ?: 0f,
                            call.argument<Float>("dy") ?: 0f,
                            call.argument<Int>("buttons") ?: 0,
                        )
                        result.success(null)
                    }
                    "requestKeyframe" -> {
                        OpenNowNative.requestKeyframe()
                        result.success(null)
                    }
                    "diagnostics" -> result.success(OpenNowNative.diagnostics())
                    else -> result.notImplemented()
                }
            } catch (error: Throwable) {
                result.error("STREAM_ERROR", error.message, JSONObject().toString())
            }
        }
    }

    override fun onDestroy() {
        if (streamTextureId != -1) {
            OpenNowNative.surfaceReleased()
            streamTextureId = -1
        }
        OpenNowNative.streamStop()
        super.onDestroy()
    }
}
