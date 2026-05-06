package com.example.mow_events.alarm

import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * نشاط Flutter لمنبّه ملء الشاشة — الصوت/الاهتزاز أصلي؛ الواجهة في [AlarmScreen].
 */
class FullScreenAlarmActivity : FlutterActivity() {

    private var mediaPlayer: MediaPlayer? = null
    private var ringingChannel: MethodChannel? = null

    private var payload: Map<String, Any?> = emptyMap()

    override fun getInitialRoute(): String = "/alarm"

    override fun onCreate(savedInstanceState: Bundle?) {
        applyLockScreenUiFlags()
        refreshPayloadFromIntent(intent)
        super.onCreate(savedInstanceState)
        startNativeAlarmFeedback()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        refreshPayloadFromIntent(intent)
        stopNativeAlarmFeedback()
        startNativeAlarmFeedback()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // نفس قناة المنبّه كما في [MainActivity] لتفادي MissingPluginException على هذا المحرك
        AlarmMethodChannel.register(this, flutterEngine)
        ringingChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RINGING_CHANNEL,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPayload" -> result.success(payload)
                    "stopNativeRinging" -> {
                        stopNativeAlarmFeedback()
                        result.success(null)
                    }
                    "dismiss" -> {
                        dismissAlarm()
                        result.success(null)
                    }
                    "snoozeFiveMinutes" -> {
                        snoozeFiveMinutes()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun applyLockScreenUiFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
    }

    private fun refreshPayloadFromIntent(incoming: Intent) {
        payload = mapOf(
            "eventId" to (incoming.getStringExtra("eventId") ?: ""),
            "requestCode" to incoming.getIntExtra("requestCode", 0),
            "eventStartTime" to incoming.getLongExtra("eventStartTime", 0L),
            "title" to (incoming.getStringExtra("title") ?: "⏰ تذكير الحدث"),
            "location" to (incoming.getStringExtra("location") ?: ""),
            "startTime" to (incoming.getStringExtra("startTime") ?: ""),
            "snoozeMinutesConfig" to incoming.getIntExtra("snoozeMinutes", 10),
        )
    }

    private fun startNativeAlarmFeedback() {
        startAlarmSound()
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        if (vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(longArrayOf(0, 500, 500), 0),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 500, 500), 0)
            }
        }
    }

    private fun stopNativeAlarmFeedback() {
        try {
            val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
            vibrator.cancel()
        } catch (_: Exception) {
        }
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    private fun startAlarmSound() {
        val candidates = mutableListOf<Uri>()
        val stored = AlarmRingtoneStore.getCustomUriString(this)
        if (!stored.isNullOrBlank()) {
            try {
                candidates.add(Uri.parse(stored))
            } catch (_: Exception) {
            }
        }
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)?.let { candidates.add(it) }
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)?.let { candidates.add(it) }

        for (alarmUri in candidates.distinct()) {
            try {
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                mp.setDataSource(this, alarmUri)
                mp.isLooping = true
                mp.prepare()
                mp.start()
                mediaPlayer = mp
                return
            } catch (_: Exception) {
            }
        }
    }

    private fun dismissAlarm() {
        val rc = intent.getIntExtra("requestCode", 0)
        AlarmScheduler.cancel(applicationContext, rc)
        NotificationHelper.cancel(applicationContext, rc)
        stopNativeAlarmFeedback()
        finish()
    }

    private fun snoozeFiveMinutes() {
        val now = System.currentTimeMillis()
        val delayMs = 5 * 60_000L
        AlarmScheduler.snooze(
            applicationContext,
            now + delayMs,
            intent.getStringExtra("eventId") ?: "",
            intent.getIntExtra("requestCode", 0),
            intent.getLongExtra("eventStartTime", 0L),
            intent.getStringExtra("title") ?: "",
            intent.getStringExtra("location") ?: "",
            intent.getStringExtra("startTime") ?: "",
            5,
        )
        NotificationHelper.cancel(applicationContext, intent.getIntExtra("requestCode", 0))
        stopNativeAlarmFeedback()
        finish()
    }

    override fun onPause() {
        super.onPause()
        try {
            mediaPlayer?.pause()
        } catch (_: Exception) {
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            if (mediaPlayer != null && !mediaPlayer!!.isPlaying) {
                mediaPlayer!!.start()
            }
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        stopNativeAlarmFeedback()
        super.onDestroy()
    }

    private companion object {
        const val RINGING_CHANNEL = "alarm_ringing_channel"
    }
}
