package com.example.mow_events.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.mow_events.R
import com.example.mow_events.MainActivity

/**
 * إشعار منبّه عاجل + واجهة [FullScreenAlarmActivity]:
 * - [setFullScreenIntent] للظهور فوق القفل/الـ heads-up عند السماح للتطبيق.
 * - [tryLaunchFullScreenAlarmUi] مباشرة بعد الإشعار لأن النظام غالباً لا يطلق الـ FSI تلقائياً
 *   (خاصة Android 10+) فيبقى المستخدم مع إشعار فقط بدون شاشة المنبّه.
 */
object NotificationHelper {

    /** قناة جديدة بأقصى أهمية — تغيير المعرف يفرض إعادة إنشاء القناة على الأجهزة القديمة. */
    private const val CHANNEL_ID = "alarm_events_urgent_v3"

    private const val TAG = "NotificationHelper"

    private fun resolveAlarmSoundUri(): Uri? {
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun buildFullScreenAlarmIntent(
        context: Context,
        eventId: String,
        requestCode: Int,
        eventStartTime: Long,
        title: String,
        location: String,
        startTime: String,
        snoozeMinutes: Int,
    ): Intent {
        return Intent(context, FullScreenAlarmActivity::class.java).apply {
            putExtra("eventId", eventId)
            putExtra("requestCode", requestCode)
            putExtra("eventStartTime", eventStartTime)
            putExtra("title", title)
            putExtra("location", location)
            putExtra("startTime", startTime)
            putExtra("snoozeMinutes", snoozeMinutes)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
    }

    /**
     * يفتح واجهة المنبّه فوراً عند وصول [android.app.AlarmManager] — مكمّل لـ [setFullScreenIntent].
     */
    private fun tryLaunchFullScreenAlarmUi(context: Context, launchIntent: Intent) {
        try {
            context.applicationContext.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.w(
                TAG,
                "Direct startActivity for alarm failed; user may open from notification",
                e,
            )
        }
    }

    private fun buildOpenAppIntent(context: Context): Intent {
        return Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
    }

    fun showAlarmNotification(
        context: Context,
        eventId: String,
        requestCode: Int,
        eventStartTime: Long,
        title: String,
        location: String,
        startTime: String,
        snoozeMinutes: Int = 10,
    ) {
        createChannel(context)

        val fullIntent = buildFullScreenAlarmIntent(
            context,
            eventId,
            requestCode,
            eventStartTime,
            title,
            location,
            startTime,
            snoozeMinutes,
        )

        // FLAG_IMMUTABLE مطلوب (Android 12+)؛ UPDATE_CURRENT يحدّث extras لنفس requestCode
        val fullPending = PendingIntent.getActivity(
            context,
            requestCode,
            fullIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val openAppPending = PendingIntent.getActivity(
            context,
            requestCode + 10_000,
            buildOpenAppIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("يبدأ عند $startTime في $location")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(false)
            .setDefaults(NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
            .setVibrate(longArrayOf(0, 400, 200, 400))
            .setContentIntent(openAppPending)
            .setFullScreenIntent(fullPending, true)
            .build()

        // السيناريو الأساسي: إطلاق شاشة المنبّه فوراً حتى أثناء استخدام الهاتف.
        tryLaunchFullScreenAlarmUi(context, fullIntent)

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(requestCode, notification)
        Log.d(TAG, "[NOTIFY] requestCode=$requestCode eventId=$eventId تم نشر الإشعار فعلياً")

        // إعادة محاولة قصيرة بعد نشر الإشعار لبعض الأجهزة التي تؤخر قبول الإطلاق المباشر.
        Handler(Looper.getMainLooper()).postDelayed(
            { tryLaunchFullScreenAlarmUi(context, fullIntent) },
            650L,
        )
    }

    fun cancel(context: Context, id: Int) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(id)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        // IMPORTANCE_MAX (قناة) متاح من API 29 — أعلى أولوية لمسار fullScreenIntent
        val importance = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            NotificationManager.IMPORTANCE_MAX
        } else {
            NotificationManager.IMPORTANCE_HIGH
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "منبّهات الأحداث",
            importance,
        ).apply {
            description = "تنبيهات ملء الشاشة للأحداث"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(resolveAlarmSoundUri(), attrs)
        }

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }
}
