package com.example.mow_events.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
val eventId = intent.getStringExtra("eventId") ?: ""
        val requestCode = intent.getIntExtra("requestCode", 0)

       val isLast = intent.getBooleanExtra("isLast", false)
        val eventStartTime = intent.getLongExtra("eventStartTime", 0L)  
  val title = intent.getStringExtra("title") ?: "⏰ تذكير الحدث"
    val location = intent.getStringExtra("location") ?: "غير محدد"
    val startTime = intent.getStringExtra("startTime") ?: "غير معروف"
 val i = Intent(context, AlarmActivity::class.java).apply {
    putExtra("eventId", eventId)
    putExtra("requestCode", requestCode)
    putExtra("eventStartTime", eventStartTime)
    putExtra("title", title)
    putExtra("location", location)
    putExtra("startTime", startTime)
    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
}
context.startActivity(i)

if (isLast) {
    NotificationHelper.showAlarmNotification(
        context,
        eventId,
        requestCode,
          eventStartTime,
            title,
            location,
            startTime
    )
} else {
    val i = Intent(context, AlarmActivity::class.java).apply {
            putExtra("eventId", eventId)
            putExtra("requestCode", requestCode)
            putExtra("eventStartTime", eventStartTime)
            putExtra("title", title)
            putExtra("location", location)
            putExtra("startTime", startTime)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    context.startActivity(i)
}

    }
}
