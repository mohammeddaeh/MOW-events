package com.example.mow_events.alarm

import io.flutter.plugin.common.MethodChannel

/**
 * يطبّقه [MainActivity] فقط — لإطلاق منتقي النظام/الملفات مع إرجاع النتيجة إلى Flutter.
 */
interface AlarmRingtonePickerHost {
    fun startSystemAlarmRingtonePicker(pendingResult: MethodChannel.Result)

    fun startAlarmAudioDocumentPicker(pendingResult: MethodChannel.Result)
}
