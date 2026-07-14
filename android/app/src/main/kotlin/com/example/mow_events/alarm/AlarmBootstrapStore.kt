package com.example.mow_events.alarm

import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * لقطة JSON للمنبّهات المستقبلية — تُستعاد بعد إعادة التشغيل.
 */
object AlarmBootstrapStore {
    private const val PREFS = "event_alarm_bootstrap"
    private const val KEY_JSON = "scheduled_json"
    private const val TAG = "AlarmSnapshot"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_JSON, json)
            .apply()
        logSnapshot("SAVE", json)
    }

    fun loadJson(context: Context): String {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_JSON, "[]") ?: "[]"
    }

    /** يطبع محتوى اللقطة الحالية (requestCode/eventId/time) لتتبّع التزامن مع الإطلاق والحذف. */
    fun logCurrentSnapshot(context: Context, tag: String) {
        logSnapshot(tag, loadJson(context))
    }

    private fun logSnapshot(tag: String, json: String) {
        try {
            val arr = JSONArray(json)
            Log.d(TAG, "[$tag] عدد المنبّهات في اللقطة: ${arr.length()}")
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                Log.d(
                    TAG,
                    "[$tag]  - requestCode=${o.optInt("requestCode")} " +
                        "eventId=${o.optString("eventId")} " +
                        "time=${o.optLong("time")} " +
                        "title=${o.optString("title")}",
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "[$tag] تعذّرت قراءة اللقطة: $json", e)
        }
    }
}
