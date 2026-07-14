package com.example.mow_events.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * يستقبل إطلاق المنبّه. [NotificationHelper.showAlarmNotification] يعرض إشعاراً عالياً
 * الأهمية مع [setFullScreenIntent] **ويحاول** فتح [FullScreenAlarmActivity] مباشرة حتى لا يبقى
 * المستخدم مع إشعار فقط (سلوك شائع عندما لا يُطلق النظام الـ FSI تلقائياً).
 */
class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        val eventId = intent.getStringExtra("eventId") ?: ""
        val requestCode = intent.getIntExtra("requestCode", 0)
        val eventStartTime = intent.getLongExtra("eventStartTime", 0L)
        val title = intent.getStringExtra("title") ?: "⏰ تذكير الحدث"
        val location = intent.getStringExtra("location") ?: ""
        val startTime = intent.getStringExtra("startTime") ?: ""
        val snoozeMinutes = intent.getIntExtra("snoozeMinutes", 10)

        Log.d(TAG, "===== إطلاق منبّه: requestCode=$requestCode eventId=$eventId title=$title =====")

        // مقارنة: هل هذا المنبّه المُطلَق لا يزال ضمن اللقطة المجدولة من الطرف Dart؟
        // إن ظهر هنا رغم حذفه، فهناك عدم تزامن بين cancelForEventId والجدولة الفعلية.
        val snapshotJson = AlarmBootstrapStore.loadJson(appContext)
        val stillInSnapshot = try {
            val arr = org.json.JSONArray(snapshotJson)
            (0 until arr.length()).any { i -> arr.getJSONObject(i).optInt("requestCode") == requestCode }
        } catch (_: Exception) {
            false
        }
        Log.d(
            TAG,
            "requestCode=$requestCode " +
                if (stillInSnapshot) "موجود في اللقطة الحالية (متوقّع)" else "غير موجود في اللقطة الحالية (قد يكون مُلغى/قديم ولم يُلغَ من AlarmManager فعلياً)",
        )
        AlarmBootstrapStore.logCurrentSnapshot(appContext, "ON_RECEIVE requestCode=$requestCode")

        val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        val wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "mow_events:AlarmReceiverWakeLock",
        )
        wakeLock.acquire(30_000L)

        try {
            NotificationHelper.showAlarmNotification(
                appContext,
                eventId,
                requestCode,
                eventStartTime,
                title,
                location,
                startTime,
                snoozeMinutes,
            )
        } finally {
            if (wakeLock.isHeld) wakeLock.release()
        }
    }

    private companion object {
        private const val TAG = "AlarmReceiver"
    }
}
