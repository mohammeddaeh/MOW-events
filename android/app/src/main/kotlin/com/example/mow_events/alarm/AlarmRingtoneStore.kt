package com.example.mow_events.alarm

import android.content.Context

/**
 * تفضيل نغمة المنبّه للتطبيق — يُقرأ من [FullScreenAlarmActivity] بدون تشغيل Flutter.
 * القيمة `null` أو فارغة = استخدام نغمة المنبّه الافتراضية في النظام.
 */
object AlarmRingtoneStore {

    private const val PREFS_NAME = "mow_alarm_ringtone"
    private const val KEY_CUSTOM_URI = "custom_alarm_uri"
    private const val KEY_SOURCE = "custom_alarm_source"

    const val SOURCE_DEFAULT = "default"
    const val SOURCE_DEVICE = "device"
    const val SOURCE_STORAGE = "storage"

    fun getCustomUriString(context: Context): String? {
        val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val s = p.getString(KEY_CUSTOM_URI, null)?.trim().orEmpty()
        return s.ifEmpty { null }
    }

    fun setCustomUriString(context: Context, uriString: String?) {
        val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (uriString.isNullOrBlank()) {
            p.edit()
                .remove(KEY_CUSTOM_URI)
                .putString(KEY_SOURCE, SOURCE_DEFAULT)
                .apply()
        } else {
            p.edit().putString(KEY_CUSTOM_URI, uriString.trim()).apply()
        }
    }

    fun getSource(context: Context): String {
        val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val s = p.getString(KEY_SOURCE, null)?.trim().orEmpty()
        if (s.isNotEmpty()) return s

        val uri = getCustomUriString(context)
        if (uri.isNullOrBlank()) return SOURCE_DEFAULT
        return inferSourceFromUri(uri)
    }

    fun setSource(context: Context, source: String) {
        val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        p.edit().putString(KEY_SOURCE, source).apply()
    }

    private fun inferSourceFromUri(uri: String): String {
        val v = uri.lowercase()
        // نغمات النظام/الجهاز غالباً تأتي من media/settings.
        if (v.startsWith("content://media") || v.startsWith("content://settings")) {
            return SOURCE_DEVICE
        }
        // الملفات المختارة من التخزين (Documents/Downloads/Files providers).
        if (v.startsWith("content://")) return SOURCE_STORAGE
        // مسارات الملفات أو أي صيغة غير متوقعة: نتعامل معها كتخزين.
        return SOURCE_STORAGE
    }
}
