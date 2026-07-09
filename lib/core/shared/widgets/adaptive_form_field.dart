import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';

enum AdaptiveFieldType {
  text,
  email,
  password,
  select,
  date,
  time,
  note,
  phone,
}

String _formatDateForDisplay(DateTime date) {
  final model = DateLocalizationHelper.display(date);
  return '${model.displayDay} ${model.displayMonth} ${model.displayYear}';
}

class AdaptiveFormField<T> extends StatefulWidget {
  const AdaptiveFormField({
    super.key,
    this.controller,
    this.initialValue,
    required this.type,
    this.label,
    this.labelStyle,
    this.hintText,
    this.items,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.onSaved,
    this.prefixIcon,
    this.enabled = true,
    this.autovalidateMode,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.initialTime,
    this.locale,
    this.focusNode,
    this.readOnly = false,
    this.onDateSelected,
    this.onTimeSelected,
    this.borderColor,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final AdaptiveFieldType type;
  final String? label;
  final TextStyle? labelStyle;
  final String? hintText;
  final List<T>? items;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final Widget? prefixIcon;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final String? locale;
  final bool readOnly;
  final void Function(DateTime)? onDateSelected;
  final void Function(TimeOfDay)? onTimeSelected;
  final Color? borderColor;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AdaptiveFormField<T>> createState() => _AdaptiveFormFieldState<T>();
}

class _AdaptiveFormFieldState<T> extends State<AdaptiveFormField<T>> {
  late final TextEditingController _controller;
  StreamSubscription<String>? _calendarSubscription;
  StreamSubscription<String>? _timeFormatSubscription;
  StreamSubscription<String>? _localeSubscription;
  bool _obscure = true;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;

    _controller =
        widget.controller ??
        TextEditingController();

    _syncDisplayText();

    _calendarSubscription = DateLocalizationHelper.userCalendar.listen((_) {
      _syncDisplayText();
    });
    _timeFormatSubscription = DateLocalizationHelper.userTimeFormat.listen((_) {
      _syncDisplayText();
    });
    if (Get.isRegistered<AppLocaleController>()) {
      _localeSubscription = Get.find<AppLocaleController>().currentLang.listen((
        _,
      ) {
        _syncDisplayText();
      });
    }
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    _timeFormatSubscription?.cancel();
    _localeSubscription?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _syncDisplayText() {
    if (widget.type == AdaptiveFieldType.date && _selectedDate != null) {
      _controller.text = _formatDateForDisplay(_selectedDate!);
      return;
    }

    if (widget.type == AdaptiveFieldType.time && _selectedTime != null) {
      _controller.text = DateLocalizationHelper.formatTimeOfDay(_selectedTime!);
      return;
    }

    if (_controller.text.isEmpty && widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  TextInputType _getKeyboard() {
    switch (widget.type) {
      case AdaptiveFieldType.email:
        return TextInputType.emailAddress;
      case AdaptiveFieldType.time:
        return TextInputType.datetime;
      case AdaptiveFieldType.note:
        return TextInputType.multiline;
      case AdaptiveFieldType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  InputDecoration _decoration() {
    SizeConfig.init(context);
    final borderColor = widget.borderColor ?? AppThemeHelper.border(context);

    OutlineInputBorder outline = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1.2.w),
      borderRadius: BorderRadius.circular(10.r),
    );

    return InputDecoration(
      labelText: widget.label,

      labelStyle:
          widget.labelStyle ??
          TextStyle(
            color: AppThemeHelper.textSecondary(context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
      hintText: widget.hintText,
      hintStyle: TextStyle(color: AppThemeHelper.hintTextGrey(context)),
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: outline,
      enabledBorder: outline,

      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.8.w),
        borderRadius: BorderRadius.circular(10.r),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppThemeHelper.red(context),
          width: 1.5.w,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppThemeHelper.red(context),
          width: 1.5.w,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.type == AdaptiveFieldType.password) {
      return IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
      );
    }
    if (widget.type == AdaptiveFieldType.select) {
      return const Icon(Icons.arrow_drop_down);
    }
    if (widget.type == AdaptiveFieldType.date ||
        widget.type == AdaptiveFieldType.time) {
      return const Icon(Icons.event);
    }

    return null;
  }

  Future<void> _handleTapForDateTime() async {
    if (widget.type == AdaptiveFieldType.date) {
      final now = DateTime.now();
      final first = widget.firstDate ?? DateTime(1900);
      final last = widget.lastDate ?? DateTime(2100);
      final picked = await showDatePicker(
        context: context,
        initialDate: widget.initialDate ?? now,
        firstDate: first,
        lastDate: last,
      );
      if (picked != null) {
        _selectedDate = picked;

        _controller.text = _formatDateForDisplay(picked);

        widget.onDateSelected?.call(picked);

        widget.onChanged?.call(_formatDate(picked));
      }
    } else if (widget.type == AdaptiveFieldType.time) {
      final isDark =
          AppThemeHelper.currentBrightness(context) == Brightness.dark;

      final picked = await showTimePicker(
        context: context,
        initialTime:
            _selectedTime ??
            widget.initialTime ??
            TimeOfDay.fromDateTime(widget.initialDate ?? DateTime.now()),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              alwaysUse24HourFormat: DateLocalizationHelper.use24HourFormat,
            ),
            child: Theme(
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
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: AppThemeHelper.background(context),
                  hourMinuteColor: AppThemeHelper.buttonPrimary(context),
                  hourMinuteTextColor: isDark ? AppColors.black : Colors.white,
                  hourMinuteTextStyle: TextStyle(
                    color: isDark ? AppColors.black : Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                  ),
                  dayPeriodColor: AppThemeHelper.buttonPrimary(context),
                  dayPeriodTextColor: WidgetStateColor.resolveWith((
                    Set<WidgetState> states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? (isDark ? AppColors.black : Colors.white)
                        : AppThemeHelper.textSecondary(context);
                  }),
                  dialHandColor: AppThemeHelper.accent(context),
                  dialBackgroundColor: AppThemeHelper.accent(
                    context,
                  ).withValues(alpha: 0.15),
                  dialTextColor: AppThemeHelper.whiteBlack(context),
                  entryModeIconColor: AppThemeHelper.accent(context),
                  helpTextStyle: TextStyle(
                    color: AppThemeHelper.whiteBlack(context),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemeHelper.accent(context),
                  ),
                ),
              ),
              child: child!,
            ),
          );
        },
      );

      if (picked != null) {
        _selectedTime = picked;
        final formatted = DateLocalizationHelper.formatTimeOfDay(picked);
        _controller.text = formatted;
        widget.onChanged?.call(formatted);
        widget.onTimeSelected?.call(picked);
      }
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    if (widget.type == AdaptiveFieldType.select) {
      final items = widget.items ?? <T>[];
      return DropdownButtonFormField<T>(
        initialValue: items.contains(_controller.text as T)
            ? _controller.text as T
            : null,
        items: items
            .map(
              (e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())),
            )
            .toList(),
        onChanged: widget.enabled
            ? (v) {
                final s = v?.toString();
                _controller.text = s ?? '';
                widget.onChanged?.call(s);
              }
            : null,
        decoration: _decoration(),
      );
    }

    final isDateOrTime =
        widget.type == AdaptiveFieldType.date ||
        widget.type == AdaptiveFieldType.time;

    final isNote = widget.type == AdaptiveFieldType.note;

    return TextFormField(
      controller: _controller,
      keyboardType: _getKeyboard(),
      obscureText: widget.type == AdaptiveFieldType.password ? _obscure : false,
      validator: widget.validator,
      onSaved: widget.onSaved,
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      readOnly: widget.readOnly || isDateOrTime,
      decoration: _decoration(),
      onTap: isDateOrTime ? () => _handleTapForDateTime() : null,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      inputFormatters: widget.inputFormatters,
      style: TextStyle(
        color: AppThemeHelper.whiteBlack(context),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: isNote ? 3 : 1,
      minLines: isNote ? 3 : 1,
    );
  }
}
