package com.opencloudgaming.opennow_android

import android.view.Surface

/**
 * JNI entry points implemented by flutter/rust/opennow_mobile.
 *
 * The Rust side owns the NVST streamer and (once opennow-core is exposed as a
 * library) the account/session core. Everything crossing this boundary is a
 * bounded JSON string or a plain scalar; no Dart or Java object is handed to
 * Rust except the Surface used by the video decoder.
 */
object OpenNowNative {
    init {
        System.loadLibrary("opennow_mobile")
    }

    /** Versioned JSON request/response, same envelope as docs/core-protocol.md. */
    external fun coreRequest(request: String): String

    /** Returns the next pending event as JSON, or null when the queue is empty. */
    external fun nextEvent(): String?

    /** Called once with the SurfaceTexture handed to Flutter's texture registry. */
    external fun surfaceReady(surface: Surface)

    external fun surfaceReleased()

    external fun streamStart(config: String)

    external fun streamStop()

    external fun submitKey(keyCode: Int, action: Int, modifiers: Int)

    external fun submitText(text: String)

    external fun submitMouse(dx: Float, dy: Float, buttons: Int)

    external fun requestKeyframe()

    /** Returns a JSON diagnostics snapshot for the F3-equivalent overlay. */
    external fun diagnostics(): String
}
