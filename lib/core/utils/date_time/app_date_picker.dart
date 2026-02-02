import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

typedef OnDatePicked = void Function(DateTime date);

class AppDatePicker extends StatefulWidget {
  final String label;
  final DateTime? initialValue;
  final OnDatePicked onDatePicked;

  const AppDatePicker({
    super.key,
    required this.label,
    this.initialValue,
    required this.onDatePicked,
  });

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late DateTime selectedGregorian;
  late HijriCalendar selectedHijri;

  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;

  String? displayText;

  @override
  void initState() {
    super.initState();
    selectedGregorian = widget.initialValue ?? DateTime.now();
    selectedHijri = HijriCalendar.fromDate(selectedGregorian);
    displayText = null;

    dayController = FixedExtentScrollController(
      initialItem: selectedHijri.hDay - 1,
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedHijri.hMonth - 1,
    );
    yearController = FixedExtentScrollController(
      initialItem: selectedHijri.hYear - 1400,
    );

    _updateDisplayText();
  }

  void _updateDisplayText() {
    final type = DateLocalizationHelper.userCalendar.value;

    switch (type) {
      case 'hijri':
        displayText =
            "${DateLocalizationHelper.hDay(selectedGregorian)} / "
            "${DateLocalizationHelper.hMonth(selectedGregorian)} / "
            "${DateLocalizationHelper.hYear(selectedGregorian)} هـ";
        break;

      case 'both':
      case 'gregorian':
      default:
        displayText =
            "${selectedGregorian.year.toString().padLeft(4, '0')} / "
            "${selectedGregorian.month.toString().padLeft(2, '0')} / "
            "${selectedGregorian.day.toString().padLeft(2, '0')}";
        break;
    }
  }

  void _showPicker() async {
    final type = DateLocalizationHelper.userCalendar.value;
    final useHijriPicker = type == 'hijri';

    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    if (!useHijriPicker) {
      // الميلادي أو كلاهما
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedGregorian,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: AppColors.gold,
                      onPrimary: AppColors.black,
                      onSurface: AppColors.white,
                    )
                  : ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textGray,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.gold : AppColors.primary,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          selectedGregorian = picked;
          selectedHijri = HijriCalendar.fromDate(picked);
          _updateDisplayText();
        });
        widget.onDatePicked(picked);
      }
    } else {
      // هجري
      int tempDay = selectedHijri.hDay;
      int tempMonth = selectedHijri.hMonth;
      int tempYear = selectedHijri.hYear;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppThemeHelper.background(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTexts.selectTheHijriDate,
            style: TextStyle(
              color: AppThemeHelper.whiteBlack(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            height: 200,
            child: Row(
              children: [
                _buildCupertinoColumn(
                  controller: dayController,
                  itemCount: selectedHijri.getDaysInMonth(
                    selectedHijri.hYear,
                    selectedHijri.hMonth,
                  ),
                  onSelectedItemChanged: (index) => tempDay = index + 1,
                  display: (i) => '${i + 1}',
                  isDark: isDark,
                ),
                _buildCupertinoColumn(
                  controller: monthController,
                  itemCount: 12,
                  onSelectedItemChanged: (index) => tempMonth = index + 1,
                  display: (i) => DateLocalizationHelper.isArabic
                      ? DateLocalizationHelper.hijriMonthsAr[i]
                      : DateLocalizationHelper.hijriMonthsEn[i],
                  isDark: isDark,
                ),
                _buildCupertinoColumn(
                  controller: yearController,
                  itemCount: 200,
                  onSelectedItemChanged: (index) => tempYear = 1400 + index,
                  display: (i) => '${1400 + i}',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTexts.cancel,
                style: TextStyle(color: AppThemeHelper.textSecondary(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeHelper.buttonPrimary(context),
              ),
              onPressed: () {
                selectedHijri.hDay = tempDay;
                selectedHijri.hMonth = tempMonth;
                selectedHijri.hYear = tempYear;

                final gregorian = selectedHijri.hijriToGregorian(
                  tempYear,
                  tempMonth,
                  tempDay,
                );
                setState(() {
                  selectedGregorian = gregorian;
                  _updateDisplayText();
                });

                widget.onDatePicked(gregorian);
                Navigator.pop(context);
              },
              child: Text(AppTexts.oK),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCupertinoColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) display,
    required bool isDark,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 32,
        onSelectedItemChanged: onSelectedItemChanged,
        backgroundColor: AppThemeHelper.background(context),
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: (isDark ? AppColors.gold : AppColors.primary).withOpacity(
            0.2,
          ),
        ),
        children: List.generate(
          itemCount,
          (i) => Center(
            child: Text(
              display(i),
              style: TextStyle(
                color: AppThemeHelper.whiteBlack(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppThemeHelper.border(context), width: 1.2),
          borderRadius: BorderRadius.circular(10),
          color: AppThemeHelper.background(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayText ?? widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: displayText == null
                      ? AppThemeHelper.textSecondary(context)
                      : AppThemeHelper.whiteBlack(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: AppThemeHelper.whiteBlack(context).withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// typedef OnDatePicked = void Function(DateTime date);

// class AppDatePicker extends StatefulWidget {
//   final String label;
//   final DateTime? initialValue;
//   final OnDatePicked onDatePicked;

//   const AppDatePicker({
//     super.key,
//     required this.label,
//     this.initialValue,
//     required this.onDatePicked,
//   });

//   @override
//   State<AppDatePicker> createState() => _AppDatePickerState();
// }

// class _AppDatePickerState extends State<AppDatePicker> {
//   late DateTime selectedGregorian;
//   late HijriCalendar selectedHijri;

//   late FixedExtentScrollController dayController;
//   late FixedExtentScrollController monthController;
//   late FixedExtentScrollController yearController;

//   String? displayText;

//   @override
//   void initState() {
//     super.initState();
//     selectedGregorian = widget.initialValue ?? DateTime.now();
//     selectedHijri = HijriCalendar.fromDate(selectedGregorian);
//     displayText = null;

//     dayController = FixedExtentScrollController(
//       initialItem: selectedHijri.hDay - 1,
//     );
//     monthController = FixedExtentScrollController(
//       initialItem: selectedHijri.hMonth - 1,
//     );
//     yearController = FixedExtentScrollController(
//       initialItem: selectedHijri.hYear - 1400,
//     );
//     displayText = null;
//   }

//   void _updateDisplayText() {
//     final type = DateLocalizationHelper.userCalendar.value;

//     switch (type) {
//       case 'hijri':
//         // هجري: اليوم/الشهر/السنة → الشهر بالاسم
//         displayText =
//             "${DateLocalizationHelper.hDay(selectedGregorian)} / ${DateLocalizationHelper.hMonth(selectedGregorian)} / ${DateLocalizationHelper.hYear(selectedGregorian)} هـ";
//         break;

//       case 'both':
//       case 'gregorian':
//       default:
//         // ميلادي أو كلاهما → الميلادي فقط، بالأرقام
//         displayText =
//             "${selectedGregorian.year.toString().padLeft(4, '0')} / "
//             "${selectedGregorian.month.toString().padLeft(2, '0')} / "
//             "${selectedGregorian.day.toString().padLeft(2, '0')}";
//         break;
//     }
//   }

//   void _showPicker() async {
//     final type = DateLocalizationHelper.userCalendar.value;
//     final useHijriPicker = type == 'hijri';

//     if (!useHijriPicker) {
//       // الميلادي أو كلاهما
//       final picked = await showDatePicker(
//         context: context,
//         initialDate: selectedGregorian,
//         firstDate: DateTime(2000),
//         lastDate: DateTime(2100),
//         builder: (context, child) {
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: const ColorScheme.light(
//                 primary: AppColors.primary,
//                 onPrimary: Colors.white,
//                 onSurface: AppColors.textGray,
//               ),
//               textButtonTheme: TextButtonThemeData(
//                 style: TextButton.styleFrom(foregroundColor: AppColors.primary),
//               ),
//             ),
//             child: child!,
//           );
//         },
//       );

//       if (picked != null) {
//         setState(() {
//           selectedGregorian = picked;
//           _updateDisplayText();
//         });
//         widget.onDatePicked(picked);
//       }
//     } else {
//       // هجري
//       int tempDay = selectedHijri.hDay;
//       int tempMonth = selectedHijri.hMonth;
//       int tempYear = selectedHijri.hYear;

//       await showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(AppTexts.selectTheHijriDate),
//           content: SizedBox(
//             height: 200,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: CupertinoPicker(
//                     scrollController: dayController,
//                     itemExtent: 32,
//                     onSelectedItemChanged: (index) => tempDay = index + 1,
//                     children: List.generate(
//                       selectedHijri.getDaysInMonth(
//                         selectedHijri.hYear,
//                         selectedHijri.hMonth,
//                       ),
//                       (i) => Center(
//                         child: Text(
//                           '${i + 1}',
//                           style: TextStyle(
//                             color: AppThemeHelper.blackBblack(context),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: CupertinoPicker(
//                     scrollController: monthController,
//                     itemExtent: 32,
//                     onSelectedItemChanged: (index) => tempMonth = index + 1,
//                     children: List.generate(
//                       12,
//                       (i) => Center(
//                         child: Text(
//                           DateLocalizationHelper.isArabic
//                               ? DateLocalizationHelper.hijriMonthsAr[i]
//                               : DateLocalizationHelper.hijriMonthsEn[i],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: CupertinoPicker(
//                     scrollController: yearController,
//                     itemExtent: 32,
//                     onSelectedItemChanged: (index) => tempYear = 1400 + index,
//                     children: List.generate(
//                       200,
//                       (i) => Center(child: Text('${1400 + i}')),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 AppTexts.cancel,
//                 style: TextStyle(color: AppColors.textGray),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//               ),
//               onPressed: () {
//                 selectedHijri.hDay = tempDay;
//                 selectedHijri.hMonth = tempMonth;
//                 selectedHijri.hYear = tempYear;

//                 final gregorian = selectedHijri.hijriToGregorian(
//                   tempYear,
//                   tempMonth,
//                   tempDay,
//                 );
//                 setState(() {
//                   selectedGregorian = gregorian;
//                   _updateDisplayText();
//                 });

//                 widget.onDatePicked(gregorian);
//                 Navigator.pop(context);
//               },
//               child: Text(AppTexts.oK),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _showPicker,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade400, width: 1.2),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 displayText ?? widget.label,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: displayText == null
//                       ? AppColors.textGray
//                       : AppThemeHelper.whiteBlack(context),
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Icon(Icons.calendar_today, size: 20, color: AppColors.textGray),
//           ],
//         ),
//       ),
//     );
//   }
// }
