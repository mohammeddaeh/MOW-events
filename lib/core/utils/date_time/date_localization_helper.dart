import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class DateLocalizationHelper {
  static RxString userCalendar = 'gregorian'.obs;

  static HijriCalendar toHijri(DateTime date) => HijriCalendar.fromDate(date);
  static late AppStorage _appStorage;

  static Rx today = DateTime.now().obs;
  static Timer? _timer;

  static void init() {
    _appStorage = AppStorage();

    userCalendar.value = _appStorage.calendar;
  }

  static void save(String value) {
    userCalendar.value = value;
    _appStorage.setCalendar(value);
  }

  static void startTodayUpdater() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final oldToday = today.value;
      if (oldToday.year != now.year ||
          oldToday.month != now.month ||
          oldToday.day != now.day) {
        today.value = now;
      }
    });
  }

  static void stopTodayUpdater() {
    _timer?.cancel();
    _timer = null;
  }

  static String gDay(DateTime date) => DateFormat('d', localeCode).format(date);
  static String gMonth(DateTime date) => isArabic
      ? gregorianMonthsAr[date.month - 1]
      : DateFormat('MMMM').format(date);
  static String gYear(DateTime date) => DateFormat('yyyy').format(date);

  static String hDay(DateTime date) => toHijri(date).hDay.toString();
  static String hMonth(DateTime date) => isArabic
      ? hijriMonthsAr[toHijri(date).hMonth - 1]
      : hijriMonthsEn[toHijri(date).hMonth - 1];
  static String hYear(DateTime date) => toHijri(date).hYear.toString();

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
      } else {
        final day = i - offset + 1;
        return HijriCalendar().hijriToGregorian(hYear, hMonth, day);
      }
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
      ? ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت']
      : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static const hijriMonthsAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  static const hijriMonthsEn = [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Sha’ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi’dah',
    'Dhu al-Hijjah',
  ];
  static const gregorianMonthsAr = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  static String get localeCode => Get.locale?.languageCode ?? 'ar';
  static bool get isArabic => localeCode == 'ar';

  static DateDisplayModel display(DateTime date) {
    final type = userCalendar.value;
    String day, month, year;

    switch (type) {
      case 'hijri':
        day = hDay(date);
        month = hMonth(date);
        year = '${hYear(date)} هـ';
        break;
      case 'both':
        day = '${gDay(date)} / ${hDay(date)}';
        month = '${gMonth(date)} / ${hMonth(date)}';
        year = '${gYear(date)} م / ${hYear(date)} هـ';
        break;
      default:
        day = gDay(date);
        month = gMonth(date);
        year = '${gYear(date)} م';
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
    List<int> months = [];

    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      final hMonth = toHijri(d).hMonth;
      if (!months.contains(hMonth)) months.add(hMonth);
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
      // نفس اليوم
      if (difference.inHours > 0) {
        return '${AppTexts.ago} ${difference.inHours} ${difference.inHours == 1 ? AppTexts.hour : AppTexts.hours}';
      } else if (difference.inMinutes > 0) {
        return '${AppTexts.ago} ${difference.inMinutes} ${difference.inMinutes == 1 ? AppTexts.minute : AppTexts.minutes}';
      } else {
        return AppTexts.now;
      }
    } else {
      final formattedDate = DateFormat('yyyy/MM/dd – HH:mm', 'ar').format(date);
      return formattedDate;
    }
  }
}

class DateDisplayModel {
  final String gDay, gMonth, gYear;
  final String hDay, hMonth, hYear;
  final String displayDay, displayMonth, displayYear;
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
