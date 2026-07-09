import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/event/presentation/screens/alarm_ringtone_settings_screen.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_dialog_helpers.dart';

class AddRemindersScreen extends GetView<ReminderController> {
  const AddRemindersScreen({super.key});

  Color _reminderThemeColor(BuildContext context) =>
      AppThemeHelper.buttonPrimary(context);

  void _showValidationError(Object error) {
    AppSnackBars.warningSnackBar(
      title: AppTexts.warningTitle,
      message: reminderValidationMessage(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldColor(context),
      appBar: AppBar(
        title: Text(AppTexts.alarmReminderSettingsTitle),
        actions: [
          IconButton(
            tooltip: AppTexts.reminderInfoTooltip,
            onPressed: () => showReminderGuideDialog(
              context,
              reminderColor: _reminderThemeColor(context),
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final reminders = controller.defaultReminders;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AlarmRingtoneSettingsSection(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final r = reminders[index];
                    return Card(
                      color: AppThemeHelper.blackWhite(context),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _reminderThemeColor(
                            context,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _reminderThemeColor(
                              context,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconForReminderType(r.type),
                            color: _reminderThemeColor(context),
                          ),
                        ),
                        title: Text(
                          formatReminderDisplayLabel(r.type, r.value),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppThemeHelper.whiteBlack(context),
                          ),
                        ),
                        // subtitle: Padding(
                        //   padding: const EdgeInsets.only(top: 4),
                        //   child: Text(
                        //     AppTexts.reminderPreviewDescription.trParams({
                        //       'value': '${r.value}',
                        //       'unit': r.type.localized,
                        //     }),
                        //     style: TextStyle(
                        //       color: AppThemeHelper.textSecondary(context),
                        //       fontSize: 12,
                        //     ),
                        //   ),
                        // ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: _reminderThemeColor(context),
                              ),
                              onPressed: () =>
                                  _editDefaultReminder(context, index, r),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppThemeHelper.red(context),
                              ),
                              onPressed: () =>
                                  _deleteDefaultReminder(context, index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _addDefaultReminder(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(AppTexts.addReminder),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _reminderThemeColor(context),
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _addDefaultReminder(BuildContext context) {
    ReminderType type = ReminderType.minute;
    bool applyToAllEvents = false;

    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController();
    final reminderColor = _reminderThemeColor(context);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            data: buildReminderDialogTheme(
              context,
              reminderColor: reminderColor,
            ),
            child: AlertDialog(
              title: buildReminderDialogTitle(
                context,
                AppTexts.addReminder,
                reminderColor: reminderColor,
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildReminderDialogDescriptionCard(
                        context,
                        reminderColor: reminderColor,
                      ),
                      const SizedBox(height: 16),
                      buildReminderTypeDropdown(
                        context,
                        value: type,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => type = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      buildReminderValueField(
                        context,
                        controller: valueController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      buildReminderPreviewCard(
                        context,
                        type: type,
                        valueText: valueController.text,
                        reminderColor: reminderColor,
                      ),
                      const SizedBox(height: 16),
                      Text(AppTexts.applyTo),
                      RadioGroup<bool>(
                        groupValue: applyToAllEvents,
                        onChanged: (v) =>
                            setState(() => applyToAllEvents = v ?? false),
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              value: false,
                              title: Text(AppTexts.futureEventsOnly),
                            ),
                            RadioListTile<bool>(
                              value: true,
                              title: Text(AppTexts.allEvents),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
                ElevatedButton(
                  child: Text(AppTexts.add),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final value = int.parse(valueController.text);
                    try {
                      ReminderController.to.validateDefaultReminder(
                        type: type,
                        value: value,
                      );
                    } catch (error) {
                      _showValidationError(error);
                      return;
                    }

                    final reminder = DefaultReminder(type: type, value: value);
                    final applyToAll = applyToAllEvents;

                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      try {
                        await ReminderController.to.addDefaultReminder(
                          reminder,
                          applyToAllEvents: applyToAll,
                        );
                        if (Get.context != null && Get.context!.mounted) {
                          AppSnackBars.successSnackBar(
                            title: AppTexts.success,
                            message: AppTexts.reminderAddedSuccessfully,
                          );
                        }
                      } catch (error) {
                        _showValidationError(error);
                      }
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    ).then(
      (_) => Future.delayed(
        const Duration(milliseconds: 400),
        () => valueController.dispose(),
      ),
    );
  }

  void _editDefaultReminder(
    BuildContext context,
    int index,
    DefaultReminder r,
  ) {
    ReminderType type = r.type;
    bool applyToAllEvents = false;
    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController(text: r.value.toString());
    final reminderColor = _reminderThemeColor(context);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            data: buildReminderDialogTheme(
              context,
              reminderColor: reminderColor,
            ),
            child: AlertDialog(
              title: buildReminderDialogTitle(
                context,
                AppTexts.editReminder,
                reminderColor: reminderColor,
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildReminderDialogDescriptionCard(
                        context,
                        reminderColor: reminderColor,
                      ),
                      const SizedBox(height: 16),
                      buildReminderTypeDropdown(
                        context,
                        value: type,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => type = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      buildReminderValueField(
                        context,
                        controller: valueController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      buildReminderPreviewCard(
                        context,
                        type: type,
                        valueText: valueController.text,
                        reminderColor: reminderColor,
                      ),
                      const SizedBox(height: 16),
                      Text(AppTexts.applyEditTo),
                      RadioGroup<bool>(
                        groupValue: applyToAllEvents,
                        onChanged: (v) =>
                            setState(() => applyToAllEvents = v ?? false),
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              value: false,
                              title: Text(AppTexts.futureEventsOnly),
                            ),
                            RadioListTile<bool>(
                              value: true,
                              title: Text(
                                AppTexts.allEventsContainingThisReminder,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final value = int.parse(valueController.text);
                    try {
                      ReminderController.to.validateDefaultReminder(
                        type: type,
                        value: value,
                        editingIndex: index,
                      );
                    } catch (error) {
                      _showValidationError(error);
                      return;
                    }

                    try {
                      await ReminderController.to.updateDefaultReminder(
                        index,
                        type,
                        value,
                        applyToAllEvents: applyToAllEvents,
                      );

                      if (!context.mounted) return;
                      Get.back();
                      AppSnackBars.successSnackBar(
                        title: AppTexts.success,
                        message: AppTexts.reminderUpdatedSuccessfully,
                      );
                    } catch (error) {
                      _showValidationError(error);
                    }
                  },
                  child: Text(AppTexts.save),
                ),
              ],
            ),
          );
        },
      ),
    ).then(
      (_) => Future.delayed(
        const Duration(milliseconds: 400),
        () => valueController.dispose(),
      ),
    );
  }

  void _deleteDefaultReminder(BuildContext context, int index) {
    bool applyToAllEvents = false;
    final reminderColor = _reminderThemeColor(context);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            data: buildReminderDialogTheme(
              context,
              reminderColor: reminderColor,
            ),
            child: AlertDialog(
              title: buildReminderDialogTitle(
                context,
                AppTexts.deleteReminder,
                reminderColor: reminderColor,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppTexts.ifyouAreSureAboutDeleting),
                  const SizedBox(height: 16),
                  RadioGroup<bool>(
                    groupValue: applyToAllEvents,
                    onChanged: (v) =>
                        setState(() => applyToAllEvents = v ?? false),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: false,
                          title: Text(AppTexts.futureEventsOnly),
                        ),
                        RadioListTile<bool>(
                          value: true,
                          title: Text(AppTexts.allEventsContainingThisReminder),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await ReminderController.to.removeDefaultReminder(
                        index,
                        applyToAllEvents: applyToAllEvents,
                      );

                      if (!context.mounted) return;
                      Get.back();
                      AppSnackBars.successSnackBar(
                        title: AppTexts.success,
                        message: AppTexts.reminderDeletedSuccessfully,
                      );
                    } catch (error) {
                      _showValidationError(error);
                    }
                  },
                  child: Text(AppTexts.delete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForReminderType(ReminderType type) {
    switch (type) {
      case ReminderType.day:
        return Icons.calendar_month_outlined;
      case ReminderType.hours:
        return Icons.watch_later_outlined;
      case ReminderType.minute:
        return Icons.timer_outlined;
    }
  }
}
