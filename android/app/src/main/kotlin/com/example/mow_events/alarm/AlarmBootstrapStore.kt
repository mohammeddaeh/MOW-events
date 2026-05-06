package com.example.mow_events.alarm

import android.content.Context

/**
 * لقطة JSON للمنبّهات المستقبلية — تُستعاد بعد إعادة التشغيل.
 */
object AlarmBootstrapStore {
    private const val PREFS = "event_alarm_bootstrap"
    private const val KEY_JSON = "scheduled_json"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_JSON, json)
            .apply()
    }

    fun loadJson(context: Context): String {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_JSON, "[]") ?: "[]"
    }
}
