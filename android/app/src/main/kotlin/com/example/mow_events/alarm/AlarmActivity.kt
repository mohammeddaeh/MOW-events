package com.example.mow_events.alarm

import android.app.Activity
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import com.example.mow_events.R

class AlarmActivity : Activity() {

    private lateinit var mediaPlayer: MediaPlayer
    private var requestCode: Int = 0
    private var eventId: String = ""
    private var eventStartTime: Long = 0L
    private val SNOOZE_MINUTES = 5L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_alarm)

        // ✨ استلام البيانات من Intent
        val eventTitle = intent.getStringExtra("title") ?: "⏰ تذكير الحدث"
        val eventLocation = intent.getStringExtra("location") ?: ""
        val eventStartTimeStr = intent.getStringExtra("startTime") ?: ""

        eventId = intent.getStringExtra("eventId") ?: ""
        requestCode = intent.getIntExtra("requestCode", 0)
        eventStartTime = intent.getLongExtra("eventStartTime", 0L)

        // ✨ إعداد TextViews
        findViewById<TextView>(R.id.txtEventTitle).text = eventTitle
        findViewById<TextView>(R.id.txtEventLocation).text = eventLocation
        findViewById<TextView>(R.id.txtEventStartTime).text = eventStartTimeStr

        // ✨ إظهار الشاشة عند القفل
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        // ✨ التحكم في زر الغفوة
        val remainingTime = eventStartTime - System.currentTimeMillis()
        val canSnooze = remainingTime > SNOOZE_MINUTES * 60 * 1000
        findViewById<Button>(R.id.btnSnooze).visibility =
            if (canSnooze) View.VISIBLE else View.GONE

        // ✨ تشغيل الصوت
        mediaPlayer = MediaPlayer.create(this, R.raw.alarm_sound)
        mediaPlayer.isLooping = true
        mediaPlayer.start()

        // ✨ الاهتزاز
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        if (vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(longArrayOf(0, 500, 500), 0)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 500, 500), 0)
            }
        }

        // ✨ زر الإيقاف
        findViewById<Button>(R.id.btnStop).setOnClickListener {
            AlarmScheduler.cancel(this, requestCode)
            stopAlarm()
        }

        // ✨ زر الغفوة
        findViewById<Button>(R.id.btnSnooze).setOnClickListener {
            handleSnooze()
        }
    }

    private fun handleSnooze() {
        val now = System.currentTimeMillis()
        val remaining = eventStartTime - now

        if (remaining <= 0) {
            stopAlarm()
            return
        }

        val snoozeDuration = minOf(
            SNOOZE_MINUTES * 60 * 1000,
            remaining - 1000
        )

        if (snoozeDuration <= 0) {
            stopAlarm()
            return
        }

        AlarmScheduler.snooze(
            this,
            now + snoozeDuration,
            eventId,
            requestCode,
eventStartTime,
    findViewById<TextView>(R.id.txtEventTitle).text.toString(),
    findViewById<TextView>(R.id.txtEventLocation).text.toString(),
    findViewById<TextView>(R.id.txtEventStartTime).text.toString()
        )

        stopAlarm()
    }

    private fun stopAlarm() {
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        vibrator.cancel()

        if (::mediaPlayer.isInitialized) {
            mediaPlayer.stop()
            mediaPlayer.release()
        }
        finish()
    }
}
