import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class DateLocalizationHelper {
  static RxString userCalendar = 'gregorian'.obs;
  static RxString userTimeFormat = '24h'.obs;

  static HijriCalendar toHijri(DateTime date) => HijriCalendar.fromDate(date);
  static late AppStorage _appStorage;

  static Rx<DateTime> today = _normalizeDay(DateTime.now()).obs;
  static Timer? _timer;

  static void init() {
    _appStorage = AppStorage();
    userCalendar.value = _appStorage.calendar;
    userTimeFormat.value = _normalizeTimeFormat(_appStorage.timeFormat);
  }

  static void save(String value) {
    userCalendar.value = value;
    _appStorage.setCalendar(value);
  }

  static void saveTimeFormat(String value) {
    final normalized = _normalizeTimeFormat(value);
    userTimeFormat.value = normalized;
    _appStorage.setTimeFormat(normalized);
  }

  static String _normalizeTimeFormat(String value) {
    return value == '12h' ? '12h' : '24h';
  }

  static bool get use24HourFormat => userTimeFormat.value != '12h';

  static void startTodayUpdater() {
    _timer?.cancel();
    today.value = _normalizeDay(DateTime.now());
    _scheduleNextTodayUpdate();
  }

  static void stopTodayUpdater() {
    _timer?.cancel();
    _timer = null;
  }

  static DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static void _scheduleNextTodayUpdate() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);

    _timer = Timer(delay, () {
      today.value = _normalizeDay(DateTime.now());
      _scheduleNextTodayUpdate();
    });
  }

  static String get localeCode => Get.locale?.languageCode ?? 'ar';
  static bool get isArabic => localeCode == 'ar';

  static String localizeDigits(String input) {
    if (!isArabic || input.isEmpty) return input;

    const westernDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicDigits = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
    ];

    var value = input;
    for (int i = 0; i < westernDigits.length; i++) {
      value = value.replaceAll(westernDigits[i], arabicDigits[i]);
    }
    return value;
  }

  static String twoDigits(int value) =>
      localizeDigits(value.toString().padLeft(2, '0'));

  static String gDay(DateTime date) =>
      localizeDigits(DateFormat('d', 'en').format(date));

  static String gMonth(DateTime date) => isArabic
      ? gregorianMonthsAr[date.month - 1]
      : DateFormat('MMMM', 'en').format(date);

  static String gYear(DateTime date) =>
      localizeDigits(DateFormat('yyyy', 'en').format(date));

  static String hDay(DateTime date) =>
      localizeDigits(toHijri(date).hDay.toString());

  static String hMonth(DateTime date) => hijriMonthName(toHijri(date).hMonth);

  static String hYear(DateTime date) =>
      localizeDigits(toHijri(date).hYear.toString());

  static String hijriMonthName(int hMonth) =>
      isArabic ? hijriMonthsAr[hMonth - 1] : hijriMonthsEn[hMonth - 1];

  static String formatTime(DateTime date, {bool withPeriod = true}) {
    return formatTimeOfDay(
      TimeOfDay(hour: date.hour, minute: date.minute),
      withPeriod: withPeriod,
    );
  }

  static String formatTimeOfDay(
    TimeOfDay time, {
    bool withPeriod = true,
  }) {
    if (use24HourFormat) {
      return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final base = '${twoDigits(hour)}:${twoDigits(time.minute)}';
    if (!withPeriod) {
      return base;
    }

    final periodText =
        time.period == DayPeriod.am ? AppTexts.amPeriod : AppTexts.pmPeriod;
    return '$base $periodText';
  }

  static String formatDateLine(DateTime date, {bool includeYear = true}) {
    switch (userCalendar.value) {
      case 'hijri':
        return _buildHijriLine(date, includeYear: includeYear);
      case 'gregorian':
      default:
        return _buildGregorianLine(date, includeYear: includeYear);
    }
  }

  static List<String> formatDateLines(
    DateTime date, {
    bool includeYear = true,
    bool includeCalendarLabelsForBoth = true,
  }) {
    final gregorianLine = _buildGregorianLine(date, includeYear: includeYear);
    final hijriLine = _buildHijriLine(date, includeYear: includeYear);

    switch (userCalendar.value) {
      case 'hijri':
        return [hijriLine];
      case 'both':
        if (!includeCalendarLabelsForBoth) {
          return [gregorianLine, hijriLine];
        }
        return [
          '${AppTexts.gregorian}: $gregorianLine',
          '${AppTexts.hijri}: $hijriLine',
        ];
      case 'gregorian':
      default:
        return [gregorianLine];
    }
  }

  static String formatCompactDateTime(
    DateTime date, {
    bool includeYear = true,
  }) {
    final lines = formatDateLines(
      date,
      includeYear: includeYear,
      includeCalendarLabelsForBoth: false,
    );
    final dateText = userCalendar.value == 'both'
        ? lines.join(' / ')
        : lines.first;
    return '$dateText - ${formatTime(date)}';
  }

  static String _buildGregorianLine(DateTime date, {bool includeYear = true}) {
    final yearSuffix = includeYear ? ' ${gYear(date)} ${AppTexts.m}' : '';
    return '${gDay(date)} ${gMonth(date)}$yearSuffix';
  }

  static String _buildHijriLine(DateTime date, {bool includeYear = true}) {
    final yearSuffix = includeYear ? ' ${hYear(date)} ${AppTexts.h}' : '';
    return '${hDay(date)} ${hMonth(date)}$yearSuffix';
  }

  static List<DateTime> generateMonthDays(DateTime month) {
    if (userCalendar.value == 'hijri') {
      final h = toHijri(month);
      return generateHijriMonthGrid(h.hYear, h.hMonth);
    }
    return generateGregorianMonthGrid(month);
  }

  static bool isInSameMonth(DateTime day, DateTime month) {
    if (userCalendar.value == 'hijri') {
      final hDay = toHijri(day);
      final hMonth = toHijri(month);
      return hDay.hMonth == hMonth.hMonth && hDay.hYear == hMonth.hYear;
    }
    return day.month == month.month && day.year == month.year;
  }

  static List<DateTime> generateGregorianMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final offset = first.weekday % 7;
    final total = last.day + offset;

    return List.generate(total, (i) {
      return first.subtract(Duration(days: offset - i));
    });
  }

  static List<DateTime> generateHijriMonthGrid(int hYear, int hMonth) {
    final firstHijri = HijriCalendar()
      ..hYear = hYear
      ..hMonth = hMonth
      ..hDay = 1;

    final total = firstHijri.getDaysInMonth(hYear, hMonth);
    final firstG = HijriCalendar().hijriToGregorian(hYear, hMonth, 1);
    final offset = firstG.weekday % 7;

    return List.generate(offset + total, (i) {
      if (i < offset) {
        return firstG.subtract(Duration(days: offset - i));
      }

      final day = i - offset + 1;
      return HijriCalendar().hijriToGregorian(hYear, hMonth, day);
    });
  }

  static bool isInMonth(DateTime day, DateTime month) {
    if (userCalendar.value == 'hijri') {
      final dh = toHijri(day);
      final mh = toHijri(month);
      return dh.hMonth == mh.hMonth && dh.hYear == mh.hYear;
    }
    return day.month == month.month && day.year == month.year;
  }

  static List<String> getWeekDaysName() => isArabic
      ? const [
          '\u0623\u062D\u062F',
          '\u0627\u062B\u0646\u064A\u0646',
          '\u062B\u0644\u0627\u062B\u0627\u0621',
          '\u0623\u0631\u0628\u0639\u0627\u0621',
          '\u062E\u0645\u064A\u0633',
          '\u062C\u0645\u0639\u0629',
          '\u0633\u0628\u062A',
        ]
      : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static const hijriMonthsAr = [
    '\u0645\u062D\u0631\u0645',
    '\u0635\u0641\u0631',
    '\u0631\u0628\u064A\u0639 \u0627\u0644\u0623\u0648\u0644',
    '\u0631\u0628\u064A\u0639 \u0627\u0644\u0622\u062E\u0631',
    '\u062C\u0645\u0627\u062F\u0649 \u0627\u0644\u0623\u0648\u0644\u0649',
    '\u062C\u0645\u0627\u062F\u0649 \u0627\u0644\u0622\u062E\u0631\u0629',
    '\u0631\u062C\u0628',
    '\u0634\u0639\u0628\u0627\u0646',
    '\u0631\u0645\u0636\u0627\u0646',
    '\u0634\u0648\u0627\u0644',
    '\u0630\u0648 \u0627\u0644\u0642\u0639\u062F\u0629',
    '\u0630\u0648 \u0627\u0644\u062D\u062C\u0629',
  ];

  static const hijriMonthsEn = [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  static const gregorianMonthsAr = [
    '\u0643\u0627\u0646\u0648\u0646 \u0627\u0644\u062B\u0627\u0646\u064A',
    '\u0634\u0628\u0627\u0637',
    '\u0622\u0630\u0627\u0631',
    '\u0646\u064A\u0633\u0627\u0646',
    '\u0623\u064A\u0627\u0631',
    '\u062D\u0632\u064A\u0631\u0627\u0646',
    '\u062A\u0645\u0648\u0632',
    '\u0622\u0628',
    '\u0623\u064A\u0644\u0648\u0644',
    '\u062A\u0634\u0631\u064A\u0646 \u0627\u0644\u0623\u0648\u0644',
    '\u062A\u0634\u0631\u064A\u0646 \u0627\u0644\u062B\u0627\u0646\u064A',
    '\u0643\u0627\u0646\u0648\u0646 \u0627\u0644\u0623\u0648\u0644',
  ];

  static DateDisplayModel display(DateTime date) {
    final type = userCalendar.value;
    String day;
    String month;
    String year;

    switch (type) {
      case 'hijri':
        day = hDay(date);
        month = hMonth(date);
        year = '${hYear(date)} ${AppTexts.h}';
        break;
      case 'both':
        day = '${gDay(date)} / ${hDay(date)}';
        month = '${gMonth(date)} / ${hMonth(date)}';
        year = '${gYear(date)} ${AppTexts.m} / ${hYear(date)} ${AppTexts.h}';
        break;
      default:
        day = gDay(date);
        month = gMonth(date);
        year = '${gYear(date)} ${AppTexts.m}';
    }

    return DateDisplayModel(
      gDay: gDay(date),
      gMonth: gMonth(date),
      gYear: gYear(date),
      hDay: hDay(date),
      hMonth: hMonth(date),
      hYear: hYear(date),
      displayDay: day,
      displayMonth: month,
      displayYear: year,
      type: type,
    );
  }

  static List<String> verticalMonthYear(DateTime date) {
    final model = display(date);

    switch (userCalendar.value) {
      case 'hijri':
        return [model.hMonth, model.hYear];
      case 'both':
        return [
          '${model.gMonth} / ${model.hMonth}',
          '${model.gYear} / ${model.hYear}',
        ];
      default:
        return [model.gMonth, model.gYear];
    }
  }

  static List<int> getHijriMonthsRangeForGregorianMonth(DateTime month) {
    final months = <int>[];

    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      final hMonth = toHijri(d).hMonth;
      if (!months.contains(hMonth)) {
        months.add(hMonth);
      }
    }

    return months;
  }

  static List<DateTime> generateDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final startOffset = first.weekday % 7;
    final total = last.day + startOffset;

    return List.generate(total, (i) {
      return first.subtract(Duration(days: startOffset - i));
    });
  }

  static int getHijriMonthForDate(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return hijri.hMonth;
  }

  static String formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        final value = localizeDigits('${difference.inHours}');
        final unit = difference.inHours == 1 ? AppTexts.hour : AppTexts.hours;
        return isArabic
            ? '${AppTexts.ago} $value $unit'
            : '$value $unit ${AppTexts.ago}';
      }

      if (difference.inMinutes > 0) {
        final value = localizeDigits('${difference.inMinutes}');
        final unit =
            difference.inMinutes == 1 ? AppTexts.minute : AppTexts.minutes;
        return isArabic
            ? '${AppTexts.ago} $value $unit'
            : '$value $unit ${AppTexts.ago}';
      }

      return AppTexts.now;
    }

    return formatCompactDateTime(date);
  }
}

class DateDisplayModel {
  final String gDay;
  final String gMonth;
  final String gYear;
  final String hDay;
  final String hMonth;
  final String hYear;
  final String displayDay;
  final String displayMonth;
  final String displayYear;
  final String type;

  DateDisplayModel({
    required this.gDay,
    required this.gMonth,
    required this.gYear,
    required this.hDay,
    required this.hMonth,
    required this.hYear,
    required this.displayDay,
    required this.displayMonth,
    required this.displayYear,
    required this.type,
  });
}
