package com.example.mow_events.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * جدولة دقيقة عبر [AlarmManager] — [setAlarmClock] عند التوفر (أعلى أولوية من Doze).
 */
object AlarmScheduler {

    fun schedule(
        context: Context,
        reminderTime: Long,
        eventId: String,
        requestCode: Int,
        isLast: Boolean,
        eventStartTime: Long,
        title: String,
        location: String,
        startTime: String,
        snoozeMinutes: Int = 10,
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("eventId", eventId)
            putExtra("requestCode", requestCode)
            putExtra("isLast", isLast)
            putExtra("eventStartTime", eventStartTime)
            putExtra("title", title)
            putExtra("location", location)
            putExtra("startTime", startTime)
            putExtra("snoozeMinutes", snoozeMinutes)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val clockInfo = AlarmManager.AlarmClockInfo(reminderTime, pendingIntent)
                alarmManager.setAlarmClock(clockInfo, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, reminderTime, pendingIntent)
            }
            Log.d(
                "AlarmScheduler",
                "[SCHEDULE] requestCode=$requestCode eventId=$eventId time=$reminderTime title=$title",
            )
        } catch (e: SecurityException) {
            Log.e("AlarmScheduler", "Cannot schedule exact alarm — check SCHEDULE_EXACT_ALARM", e)
        }
    }

    fun cancel(context: Context, requestCode: Int) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        Log.d("AlarmScheduler", "[CANCEL] requestCode=$requestCode أُلغي فعلياً من AlarmManager")
    }

    /**
     * يلغي كل المنبّهات المتتبَّعة حالياً عبر لقطة [AlarmBootstrapStore] (مثلاً عند تسجيل الخروج)
     * ثم يفرغ اللقطة حتى لا تُستعاد هذه المنبّهات بعد إعادة تشغيل الجهاز.
     */
    fun cancelAllTracked(context: Context) {
        val json = AlarmBootstrapStore.loadJson(context)
        val requestCodes = try {
            val arr = org.json.JSONArray(json)
            (0 until arr.length()).map { i -> arr.getJSONObject(i).optInt("requestCode") }
        } catch (e: Exception) {
            Log.e("AlarmScheduler", "[CANCEL_ALL] تعذّرت قراءة اللقطة: $json", e)
            emptyList()
        }

        for (requestCode in requestCodes) {
            cancel(context, requestCode)
        }

        AlarmBootstrapStore.save(context, "[]")
        Log.d("AlarmScheduler", "[CANCEL_ALL] تم إلغاء ${requestCodes.size} منبّه وتفريغ اللقطة")
    }

    fun snooze(
        context: Context,
        snoozeTime: Long,
        eventId: String,
        requestCode: Int,
        eventStartTime: Long,
        title: String,
        location: String,
        startTime: String,
        snoozeMinutes: Int,
    ) {
        schedule(
            context,
            snoozeTime,
            eventId,
            requestCode,
            true,
            eventStartTime,
            title,
            location,
            startTime,
            snoozeMinutes,
        )
    }
}
