# ================= Pushy =================
-dontwarn me.pushy.**
-keep class me.pushy.** { *; }

# ================= AndroidX Notifications =================
-keep class androidx.core.app.** { *; }

# ================= Legacy Support (safety) =================
-keep class android.support.v4.app.** { *; }

# ================= Native event alarms =================
-keep class com.example.mow_events.alarm.** { *; }
-keep class com.example.mow_events.MainActivity { *; }
