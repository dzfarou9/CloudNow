package com.opencloudgaming.opennow_android

import io.flutter.plugin.common.EventChannel

/**
 * Bridges Rust core events to the Dart EventChannel. Polling a bounded queue
 * on a daemon thread keeps event delivery off the main thread; the sink is
 * only touched by this one producer.
 */
object CoreEventStreamHandler : EventChannel.StreamHandler {
    @Volatile
    private var running = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        if (running) return
        running = true
        Thread {
            while (running) {
                val event = OpenNowNative.nextEvent()
                if (event != null) {
                    events.success(event)
                } else {
                    try {
                        Thread.sleep(50)
                    } catch (_: InterruptedException) {
                        break
                    }
                }
            }
        }.apply {
            name = "opennow-core-events"
            isDaemon = true
        }.start()
    }

    override fun onCancel(arguments: Any?) {
        running = false
    }
}
