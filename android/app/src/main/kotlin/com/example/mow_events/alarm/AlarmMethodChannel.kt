package com.example.mow_events.alarm

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * قناة `alarm_channel` — تُسجَّل لكل [FlutterEngine] (الرئيسي وشاشة المنبّه)
 * حتى لا يحدث MissingPluginException عند استدعاء Dart من عزل/نشاط مختلف.
 */
object AlarmMethodChannel {

    const val CHANNEL_NAME = "alarm_channel"
    private var previewPlayer: MediaPlayer? = null

    fun register(
        context: Context,
        engine: FlutterEngine,
        ringtonePickerHost: AlarmRingtonePickerHost? = null,
    ) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val time = call.argument<Long>("time")!!
                        val eventId = call.argument<String>("eventId")!!
                        val requestCode = call.argument<Int>("requestCode")!!
                        val isLast = call.argument<Boolean>("isLast") ?: true
                        val eventStartTime = call.argument<Long>("eventStartTime") ?: 0L
                        val title = call.argument<String>("title") ?: "⏰ تذكير الحدث"
                        val location = call.argument<String>("location") ?: ""
                        val startTime = call.argument<String>("startTime") ?: ""
                        val snoozeMinutes = call.argument<Int>("snoozeMinutes") ?: 10

                        AlarmScheduler.schedule(
                            context,
                            time,
                            eventId,
                            requestCode,
                            isLast,
                            eventStartTime,
                            title,
                            location,
                            startTime,
                            snoozeMinutes,
                        )
                        result.success(null)
                    }

                    "cancelAlarm" -> {
                        val requestCode = call.argument<Int>("requestCode")!!
                        android.util.Log.d("AlarmSnapshot", "[CANCEL] طلب إلغاء requestCode=$requestCode (AlarmManager فقط؛ اللقطة تُحدَّث لاحقاً عبر setAlarmScheduleSnapshot)")
                        AlarmScheduler.cancel(context, requestCode)
                        result.success(null)
                    }

                    "cancelAllAlarms" -> {
                        AlarmScheduler.cancelAllTracked(context)
                        result.success(null)
                    }

                    "setAlarmScheduleSnapshot" -> {
                        val json = call.argument<String>("json") ?: "[]"
                        val previousJson = AlarmBootstrapStore.loadJson(context)
                        AlarmBootstrapStore.logCurrentSnapshot(context, "SYNC_BEFORE")
                        AlarmBootstrapStore.save(context, json)
                        logSnapshotDiff(previousJson, json)
                        result.success(null)
                    }

                    "canScheduleExactAlarms" -> {
                        result.success(canScheduleExactAlarmsCompat(context))
                    }

                    "canUseFullScreenIntent" -> {
                        result.success(canUseFullScreenIntentCompat(context))
                    }

                    "areNotificationsEnabled" -> {
                        result.success(areNotificationsEnabledCompat(context))
                    }

                    "getAlarmRuntimeStatus" -> {
                        result.success(
                            mapOf(
                                "canScheduleExactAlarms" to canScheduleExactAlarmsCompat(context),
                                "canUseFullScreenIntent" to canUseFullScreenIntentCompat(context),
                                "areNotificationsEnabled" to areNotificationsEnabledCompat(context),
                                "sdkInt" to Build.VERSION.SDK_INT,
                            ),
                        )
                    }

                    "openExactAlarmSettings" -> {
                        openExactAlarmSettingsScreen(context)
                        result.success(null)
                    }

                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettingsScreen(context)
                        result.success(null)
                    }

                    "openNotificationSettings" -> {
                        openNotificationSettingsScreen(context)
                        result.success(null)
                    }

                    "openSystemSoundSettings" -> {
                        openSystemSoundSettingsScreen(context)
                        result.success(null)
                    }

                    "getAlarmRingtoneUri" -> {
                        result.success(AlarmRingtoneStore.getCustomUriString(context))
                    }

                    "getAlarmRingtoneSource" -> {
                        result.success(AlarmRingtoneStore.getSource(context))
                    }

                    "clearAlarmRingtone" -> {
                        AlarmRingtoneStore.setCustomUriString(context, null)
                        AlarmRingtoneStore.setSource(context, AlarmRingtoneStore.SOURCE_DEFAULT)
                        result.success(null)
                    }

                    "setAlarmRingtoneUri" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrBlank()) {
                            AlarmRingtoneStore.setCustomUriString(context, null)
                            AlarmRingtoneStore.setSource(context, AlarmRingtoneStore.SOURCE_DEFAULT)
                        } else {
                            AlarmRingtoneStore.setCustomUriString(context, uri)
                        }
                        result.success(null)
                    }

                    "pickSystemAlarmRingtone" -> {
                        val host = ringtonePickerHost
                        if (host == null) {
                            result.error(
                                "NO_HOST",
                                "Ringtone picker is only available from the main activity",
                                null,
                            )
                        } else {
                            host.startSystemAlarmRingtonePicker(result)
                        }
                    }

                    "pickAlarmAudioFile" -> {
                        val host = ringtonePickerHost
                        if (host == null) {
                            result.error(
                                "NO_HOST",
                                "Audio picker is only available from the main activity",
                                null,
                            )
                        } else {
                            host.startAlarmAudioDocumentPicker(result)
                        }
                    }

                    "playAlarmTonePreview" -> {
                        val uri = call.argument<String>("uri")
                        result.success(playAlarmTonePreview(context, uri))
                    }

                    "stopAlarmTonePreview" -> {
                        stopAlarmTonePreview()
                        result.success(null)
                    }

                    "getAndroidSdkInt" -> {
                        result.success(Build.VERSION.SDK_INT)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** يقارن اللقطة القديمة بالجديدة ويطبع الفروقات (requestCode المضافة/المحذوفة). */
    private fun logSnapshotDiff(previousJson: String, newJson: String) {
        fun codesOf(json: String): Set<Int> {
            return try {
                val arr = org.json.JSONArray(json)
                (0 until arr.length()).map { i -> arr.getJSONObject(i).optInt("requestCode") }.toSet()
            } catch (_: Exception) {
                emptySet()
            }
        }

        val oldCodes = codesOf(previousJson)
        val newCodes = codesOf(newJson)
        val added = newCodes - oldCodes
        val removed = oldCodes - newCodes

        android.util.Log.d(
            "AlarmSnapshot",
            "[SYNC_DIFF] قبل=${oldCodes.size} بعد=${newCodes.size} " +
                "مُضاف=$added مُلغى=$removed",
        )
        if (removed.isNotEmpty()) {
            android.util.Log.d(
                "AlarmSnapshot",
                "[SYNC_DIFF] تحقّق: يجب أن تكون requestCode التالية قد أُلغيت فعلياً من AlarmManager عبر cancelAlarm: $removed",
            )
        }
    }

    private fun canScheduleExactAlarmsCompat(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    private fun canUseFullScreenIntentCompat(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.canUseFullScreenIntent()
    }

    private fun areNotificationsEnabledCompat(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return true
        }
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.areNotificationsEnabled()
    }

    private fun openExactAlarmSettingsScreen(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                return
            } catch (_: Exception) {
            }
        }
        openApplicationDetailsSettings(context)
    }

    private fun openFullScreenIntentSettingsScreen(context: Context) {
        if (Build.VERSION.SDK_INT >= 34) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                        data = Uri.parse("package:${context.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                return
            } catch (_: Exception) {
            }
        }
        openApplicationDetailsSettings(context)
    }

    private fun openNotificationSettingsScreen(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                return
            } catch (_: Exception) {
            }
        }
        openApplicationDetailsSettings(context)
    }

    private fun openSystemSoundSettingsScreen(context: Context) {
        try {
            context.startActivity(
                Intent(Settings.ACTION_SOUND_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        } catch (_: Exception) {
            openApplicationDetailsSettings(context)
        }
    }

    private fun openApplicationDetailsSettings(context: Context) {
        try {
            context.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        } catch (_: Exception) {
        }
    }

    private fun stopAlarmTonePreview() {
        try {
            previewPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            previewPlayer?.release()
        } catch (_: Exception) {
        }
        previewPlayer = null
    }

    private fun playAlarmTonePreview(context: Context, requestedUri: String?): Boolean {
        val candidates = mutableListOf<Uri>()
        if (!requestedUri.isNullOrBlank()) {
            try {
                candidates.add(Uri.parse(requestedUri))
            } catch (_: Exception) {
            }
        }
        AlarmRingtoneStore.getCustomUriString(context)?.let {
            try {
                candidates.add(Uri.parse(it))
            } catch (_: Exception) {
            }
        }
        android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            ?.let { candidates.add(it) }
        android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
            ?.let { candidates.add(it) }

        stopAlarmTonePreview()

        for (uri in candidates.distinct()) {
            try {
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                mp.setDataSource(context.applicationContext, uri)
                mp.isLooping = false
                mp.prepare()
                mp.start()
                previewPlayer = mp
                return true
            } catch (_: Exception) {
                stopAlarmTonePreview()
            }
        }
        return false
    }
}
