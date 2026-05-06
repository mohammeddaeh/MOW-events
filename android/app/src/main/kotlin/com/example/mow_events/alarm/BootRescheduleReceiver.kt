package com.example.mow_events.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray

/**
 * إعادة جدولة منبّهات الأحداث بعد إعادة تشغيل الجهاز.
 */
class BootRescheduleReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED &&
            intent?.action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val json = AlarmBootstrapStore.loadJson(context)
        try {
            val arr = JSONArray(json)
            val now = System.currentTimeMillis()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val time = o.optLong("time", 0L)
                if (time <= now) continue

                AlarmScheduler.schedule(
                    context.applicationContext,
                    time,
                    o.optString("eventId", ""),
                    o.optInt("requestCode"),
                    o.optBoolean("isLast", true),
                    o.optLong("eventStartTime", 0L),
                    o.optString("title", "⏰ تذكير الحدث"),
                    o.optString("location", ""),
                    o.optString("startTime", ""),
                    o.optInt("snoozeMinutes", 10),
                )
            }
        } catch (_: Exception) {
        }
    }
}
