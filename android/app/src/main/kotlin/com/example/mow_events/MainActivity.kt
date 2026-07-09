package com.example.mow_events

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.example.mow_events.alarm.AlarmMethodChannel
import com.example.mow_events.alarm.AlarmRingtonePickerHost
import com.example.mow_events.alarm.AlarmRingtoneStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity(), AlarmRingtonePickerHost {

    private var pendingRingtonePick: MethodChannel.Result? = null

    private val systemAlarmRingtoneLauncher: ActivityResultLauncher<Intent> =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
            val pr = pendingRingtonePick
            pendingRingtonePick = null
            if (pr == null) return@registerForActivityResult
            try {
                if (activityResult.resultCode != Activity.RESULT_OK) {
                    pr.success(null)
                    return@registerForActivityResult
                }
                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activityResult.data?.getParcelableExtra(
                        RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                        Uri::class.java,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    activityResult.data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                }
                if (uri == null) {
                    AlarmRingtoneStore.setCustomUriString(this, null)
                    AlarmRingtoneStore.setSource(this, AlarmRingtoneStore.SOURCE_DEFAULT)
                    pr.success(null)
                } else {
                    AlarmRingtoneStore.setCustomUriString(this, uri.toString())
                    AlarmRingtoneStore.setSource(this, AlarmRingtoneStore.SOURCE_DEVICE)
                    pr.success(uri.toString())
                }
            } catch (e: Exception) {
                pr.error("RINGTONE_PICK", e.message, null)
            }
        }

    private val alarmAudioDocumentLauncher: ActivityResultLauncher<Intent> =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
            val pr = pendingRingtonePick
            pendingRingtonePick = null
            if (pr == null) return@registerForActivityResult
            try {
                if (activityResult.resultCode != Activity.RESULT_OK) {
                    pr.success(null)
                    return@registerForActivityResult
                }
                val uri = activityResult.data?.data
                if (uri == null) {
                    pr.success(null)
                    return@registerForActivityResult
                }
                try {
                    val flags = activityResult.data?.flags ?: 0
                    val takeFlags =
                        flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    if (takeFlags != 0) {
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                    }
                } catch (_: Exception) {
                }
                AlarmRingtoneStore.setCustomUriString(this, uri.toString())
                AlarmRingtoneStore.setSource(this, AlarmRingtoneStore.SOURCE_STORAGE)
                pr.success(uri.toString())
            } catch (e: Exception) {
                pr.error("AUDIO_PICK", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AlarmMethodChannel.register(this, flutterEngine, this)
    }

    override fun startSystemAlarmRingtonePicker(pendingResult: MethodChannel.Result) {
        if (pendingRingtonePick != null) {
            pendingResult.error("BUSY", "Another picker is already open", null)
            return
        }
        pendingRingtonePick = pendingResult
        try {
            val current = AlarmRingtoneStore.getCustomUriString(this)?.let { Uri.parse(it) }
            val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, current)
            }
            systemAlarmRingtoneLauncher.launch(intent)
        } catch (e: Exception) {
            pendingRingtonePick = null
            pendingResult.error("RINGTONE_PICK", e.message, null)
        }
    }

    override fun startAlarmAudioDocumentPicker(pendingResult: MethodChannel.Result) {
        if (pendingRingtonePick != null) {
            pendingResult.error("BUSY", "Another picker is already open", null)
            return
        }
        pendingRingtonePick = pendingResult
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "audio/*"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            }
            alarmAudioDocumentLauncher.launch(intent)
        } catch (e: Exception) {
            pendingRingtonePick = null
            pendingResult.error("AUDIO_PICK", e.message, null)
        }
    }
}
