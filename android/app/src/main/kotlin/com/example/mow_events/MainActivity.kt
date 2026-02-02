package com.example.mow_events

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.mow_events.alarm.AlarmScheduler
class MainActivity : FlutterActivity() {

    private val CHANNEL = "alarm_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

     MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
.setMethodCallHandler { call, result ->
    when (call.method) {
        "scheduleAlarm" -> {
            val time = call.argument<Long>("time")!!
            val eventId = call.argument<String>("eventId")!!
            val requestCode = call.argument<Int>("requestCode")!!
            val isLast = call.argument<Boolean>("isLast") ?: false
            val eventStartTime = call.argument<Long>("eventStartTime") ?: 0L
val title = call.argument<String>("title") ?: "⏰ تذكير الحدث"
val location = call.argument<String>("location") ?: ""
val startTime = call.argument<String>("startTime") ?: ""

            AlarmScheduler.schedule(
                this,
                time,
                eventId,
                requestCode,
                isLast,
                eventStartTime,
    title,
    location,
    startTime

            )

            result.success(null)
        }
        "cancelAlarm" -> {  // ← هذا هو التعديل
            val requestCode = call.argument<Int>("requestCode")!!
            AlarmScheduler.cancel(this, requestCode)
            result.success(null)
        }
        else -> result.notImplemented()
    }
}

    }
}
