import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';

String reminderValidationMessage(Object error) {
  if (error is ArgumentError) {
    final message = error.message;
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  }

  return AppTexts.anUnexpectedErrorOccurred;
}

String formatReminderDisplayLabel(ReminderType type, int value) {
  if (type == ReminderType.minute && value == 0) {
    return AppTexts.reminderAtEventTime;
  }
  return AppTexts.reminderBeforeEventLabel.trParams({
    'value': '$value',
    'unit': type.localized,
  });
}

String? validateReminderValueText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppTexts.requiredField;
  }

  final parsedValue = int.tryParse(value);
  if (parsedValue == null) {
    return AppTexts.invalidNumber;
  }

  if (parsedValue < 0) {
    return AppTexts.reminderValueCannotBeNegative;
  }

  if (parsedValue == 0) {
    return AppTexts.mustBeGreaterThanZero;
  }

  return null;
}

ThemeData buildReminderDialogTheme(
  BuildContext context, {
  Color? reminderColor,
}) {
  final baseTheme = Theme.of(context);
  final resolvedColor = reminderColor ?? AppThemeHelper.buttonPrimary(context);

  return baseTheme.copyWith(
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: resolvedColor,
      secondary: resolvedColor,
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      backgroundColor: AppThemeHelper.blackWhite(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: resolvedColor),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: resolvedColor),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return resolvedColor;
        }
        return AppThemeHelper.grey(context);
      }),
    ),
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: resolvedColor, width: 1.2),
      ),
      floatingLabelStyle: TextStyle(color: resolvedColor),
    ),
  );
}

Future<void> showReminderGuideDialog(
  BuildContext context, {
  Color? reminderColor,
}) async {
  final resolvedColor = reminderColor ?? AppThemeHelper.buttonPrimary(context);

  await showDialog<void>(
    context: context,
    builder: (_) => Theme(
      data: buildReminderDialogTheme(context, reminderColor: resolvedColor),
      child: AlertDialog(
        title: Text(AppTexts.reminderGuideTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTexts.reminderGuideDescription,
                style: TextStyle(
                  height: 1.5,
                  color: AppThemeHelper.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              _ReminderGuideStep(
                icon: Icons.timelapse_outlined,
                title: AppTexts.reminderChooseUnitLabel,
                description: AppTexts.reminderChooseUnitHint,
                reminderColor: resolvedColor,
              ),
              const SizedBox(height: 12),
              _ReminderGuideStep(
                icon: Icons.pin_outlined,
                title: AppTexts.value,
                description: AppTexts.reminderValueHint,
                reminderColor: resolvedColor,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: resolvedColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: resolvedColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: resolvedColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppTexts.reminderGuideTip,
                        style: TextStyle(
                          height: 1.5,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: Get.back, child: Text(AppTexts.done)),
        ],
      ),
    ),
  );
}

Widget buildReminderDialogTitle(
  BuildContext context,
  String title, {
  Color? reminderColor,
}) {
  return Row(
    children: [
      Expanded(child: Text(title)),
      IconButton(
        tooltip: AppTexts.reminderInfoTooltip,
        onPressed: () =>
            showReminderGuideDialog(context, reminderColor: reminderColor),
        icon: const Icon(Icons.info_outline_rounded),
      ),
    ],
  );
}

Widget buildReminderDialogDescriptionCard(
  BuildContext context, {
  Color? reminderColor,
}) {
  final resolvedColor = reminderColor ?? AppThemeHelper.buttonPrimary(context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: resolvedColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: resolvedColor.withValues(alpha: 0.14)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: resolvedColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppTexts.reminderDialogDescription,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildReminderTypeDropdown(
  BuildContext context, {
  required ReminderType value,
  required ValueChanged<ReminderType?> onChanged,
}) {
  return DropdownButtonFormField<ReminderType>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: AppTexts.reminderChooseUnitLabel,
      helperText: AppTexts.reminderChooseUnitHint,
    ),
    items: ReminderType.values
        .map(
          (reminderType) => DropdownMenuItem(
            value: reminderType,
            child: Text(reminderType.localized),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

Widget buildReminderValueField(
  BuildContext context, {
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: AppTexts.value,
      helperText: AppTexts.reminderValueHint,
    ),
    validator: validateReminderValueText,
    onChanged: onChanged,
  );
}

Widget buildReminderPreviewCard(
  BuildContext context, {
  required ReminderType type,
  required String valueText,
  Color? reminderColor,
}) {
  final resolvedColor = reminderColor ?? AppThemeHelper.buttonPrimary(context);
  final parsedValue = int.tryParse(valueText);
  final hasValidValue = parsedValue != null && parsedValue > 0;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: resolvedColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: resolvedColor.withValues(alpha: 0.14)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasValidValue ? Icons.alarm_rounded : Icons.info_outline_rounded,
          size: 18,
          color: resolvedColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasValidValue
                ? AppTexts.reminderPreviewDescription.trParams({
                    'value': '$parsedValue',
                    'unit': type.localized,
                  })
                : AppTexts.reminderDialogDescription,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReminderGuideStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color reminderColor;

  const _ReminderGuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.reminderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: reminderColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: reminderColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppThemeHelper.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
