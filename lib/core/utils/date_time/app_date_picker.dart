import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
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
  StreamSubscription<String>? _calendarSubscription;
  StreamSubscription<String>? _localeSubscription;

  String? displayText;

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null) {
      selectedGregorian = widget.initialValue!;
      selectedHijri = HijriCalendar.fromDate(selectedGregorian);
      _updateDisplayText();
    } else {
      selectedGregorian = DateTime.now();
      selectedHijri = HijriCalendar.fromDate(selectedGregorian);
      displayText = null;
    }

    dayController = FixedExtentScrollController(
      initialItem: selectedHijri.hDay - 1,
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedHijri.hMonth - 1,
    );
    yearController = FixedExtentScrollController(
      initialItem: selectedHijri.hYear - 1400,
    );

    _calendarSubscription = DateLocalizationHelper.userCalendar.listen((_) {
      if (!mounted) return;
      setState(_updateDisplayText);
    });

    if (Get.isRegistered<AppLocaleController>()) {
      _localeSubscription = Get.find<AppLocaleController>().currentLang.listen((
        _,
      ) {
        if (!mounted) return;
        setState(_updateDisplayText);
      });
    }
  }

  void _updateDisplayText() {
    final lines = DateLocalizationHelper.formatDateLines(
      selectedGregorian,
      includeCalendarLabelsForBoth: false,
    );
    displayText = DateLocalizationHelper.userCalendar.value == 'both'
        ? lines.join(' / ')
        : lines.first;
  }

  Future<void> _showPicker() async {
    final type = DateLocalizationHelper.userCalendar.value;
    final useHijriPicker = type == 'hijri';

    if (!useHijriPicker) {
      final isDark =
          AppThemeHelper.currentBrightness(context) == Brightness.dark;
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
                      onSurface: AppThemeHelper.whiteBlack(context),
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeHelper.accent(context),
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
      return;
    }

    int tempDay = selectedHijri.hDay;
    int tempMonth = selectedHijri.hMonth;
    int tempYear = selectedHijri.hYear;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeHelper.background(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                display: (i) =>
                    DateLocalizationHelper.localizeDigits('${i + 1}'),
              ),
              _buildCupertinoColumn(
                controller: monthController,
                itemCount: 12,
                onSelectedItemChanged: (index) => tempMonth = index + 1,
                display: (i) => DateLocalizationHelper.isArabic
                    ? DateLocalizationHelper.hijriMonthsAr[i]
                    : DateLocalizationHelper.hijriMonthsEn[i],
              ),
              _buildCupertinoColumn(
                controller: yearController,
                itemCount: 200,
                onSelectedItemChanged: (index) => tempYear = 1400 + index,
                display: (i) => DateLocalizationHelper.localizeDigits(
                  '${1400 + i}',
                ),
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

  Widget _buildCupertinoColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) display,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 32,
        onSelectedItemChanged: onSelectedItemChanged,
        backgroundColor: AppThemeHelper.background(context),
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: AppThemeHelper.accent(context).withOpacity(0.2),
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
  void dispose() {
    _calendarSubscription?.cancel();
    _localeSubscription?.cancel();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
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
              color: AppThemeHelper.whiteBlack(context).withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
