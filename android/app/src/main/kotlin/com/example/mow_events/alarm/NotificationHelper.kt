package com.example.mow_events.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.mow_events.R

object NotificationHelper {

    private const val CHANNEL_ID = "alarm_channel"

    fun showAlarmNotification(
        context: Context,
        eventId: String,
        requestCode: Int,
   eventStartTime: Long,
    title: String,
    location: String,
    startTime: String
    ) {

        createChannel(context)

        // Full screen intent
       val fullIntent = Intent(context, AlarmActivity::class.java).apply {
        putExtra("eventId", eventId)
        putExtra("requestCode", requestCode)
        putExtra("eventStartTime", eventStartTime)
        putExtra("title", title)
        putExtra("location", location)
        putExtra("startTime", startTime)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }


        val fullPending = PendingIntent.getActivity(
            context,
            requestCode,
            fullIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

       

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
        .setContentTitle(title)
        .setContentText("يبدأ عند $startTime في $location")
        .setCategory(NotificationCompat.CATEGORY_ALARM)
        .setPriority(NotificationCompat.PRIORITY_MAX)
        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        .setOngoing(true)
        .setAutoCancel(false)
        .setFullScreenIntent(fullPending, true)
        .build()

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        manager.notify(requestCode, notification)
    }

    fun cancel(context: Context, id: Int) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(id)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm notifications"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
               setSound(null, null)

            }

            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
