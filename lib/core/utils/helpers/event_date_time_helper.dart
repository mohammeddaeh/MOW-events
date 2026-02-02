import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class EventDateTimeHelper {
  static DateTime combine(String date, String time) {
    try {
      var d = date.trim();
      var t = time.trim();

      if ((d.contains(' ') || d.contains('T')) &&
          (t.isEmpty || t == '00:00:00')) {
        final parts = d.split(RegExp(r'[ T]'));
        if (parts.isNotEmpty) d = parts[0];
        if (parts.length > 1 && (t.isEmpty || t == '00:00:00')) t = parts[1];
      }

      if (t.contains('.')) t = t.split('.').first;
      // strip timezone like +03:00 or Z
      t = t.split(RegExp(r'[Zz]|[+-]\d{2}:?\d{2}')).first;

      final dateParts = d.contains('-') ? d.split('-') : d.split('/');
      final parsedDate = dateParts.map((p) => int.parse(p.trim())).toList();

      final timePartsRaw = (t.isEmpty || t == '00:00:00')
          ? <String>[]
          : t.split(':').map((s) => s.trim()).toList();

      final timeParts = List<int>.filled(3, 0);
      for (var i = 0; i < 3; i++) {
        if (i < timePartsRaw.length && timePartsRaw[i].isNotEmpty) {
          timeParts[i] = int.tryParse(timePartsRaw[i]) ?? 0;
        }
      }

      if (parsedDate.length != 3) {
        throw ArgumentError('Invalid date format: $date');
      }

      return DateTime(
        parsedDate[0],
        parsedDate[1],
        parsedDate[2],
        timeParts[0],
        timeParts[1],
        timeParts[2],
      );
    } catch (e) {
      throw ArgumentError('Failed to parse date/time: $date $time');
    }
  }

  static String formatDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  static String formatTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";

  static String formatTimeHhMm(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  static void validate(DateTime start, DateTime end) {
    if (start.isBefore(DateTime.now())) {
      throw ArgumentError(AppTexts.theStartDateAndTimeShouldBeFromNowOn);
    }
    if (end.isBefore(start)) {
      throw ArgumentError(AppTexts.theEndShouldComeAfterTheBeginning);
    }
  }
}
