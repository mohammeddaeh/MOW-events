import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_dialog_helpers.dart';

import '../../../../core/shared/widgets/dialoge/app_dialog.dart';

class EventRemindersSheet extends StatelessWidget {
  final EventModel event;
  final DateTime now;

  const EventRemindersSheet({super.key, required this.event, required this.now})
    : super();

  void _showValidationError(Object error) {
    AppSnackBars.warningSnackBar(
      title: AppTexts.warningTitle,
      message: reminderValidationMessage(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = event.id.toString();
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Obx(() {
                final rawList =
                    ReminderController.to.remindersMap[eventId] ?? [];
                final list = List<ReminderEntity>.from(rawList)
                  ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
                final now = DateTime.now();
                final past = list
                    .where((r) => r.reminderTime.isBefore(now))
                    .toList();
                final upcoming = list
                    .where((r) => !r.reminderTime.isBefore(now))
                    .toList();

                if (list.isEmpty) {
                  return EmptyStateWidget(
                    lottieAsset: AppImages.noResult,
                    title: AppTexts.noReminder,
                    subtitle: AppTexts.remindersWillBeSetForEvents,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _sectionHeader(
                        context,
                        AppTexts.upcomingReminders,
                        AppColors.green,
                      ),
                      ...upcoming.map(
                        (r) => KeyedSubtree(
                          key: ValueKey(
                            'reminder_${r.id}_${r.reminderTime.millisecondsSinceEpoch}',
                          ),
                          child: _ReminderCard(
                            reminder: r,
                            event: event,
                            onEdit: () => _editReminder(context, r),
                            onDelete: () => _confirmDelete(context, r),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionHeader(
                        context,
                        AppTexts.pastReminders,
                        AppColors.red,
                      ),
                      ...past.map(
                        (r) => KeyedSubtree(
                          key: ValueKey(
                            'reminder_${r.id}_${r.reminderTime.millisecondsSinceEpoch}',
                          ),
                          child: _ReminderCard(
                            reminder: r,
                            event: event,
                            onEdit: () => _editReminder(context, r),
                            onDelete: () => _confirmDelete(context, r),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            _buildAddButton(context, eventId),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppThemeHelper.border(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppThemeHelper.buttonPrimary(
                    context,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  color: AppThemeHelper.buttonPrimary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTexts.reminders,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppThemeHelper.whiteBlack(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppThemeHelper.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppTexts.reminderInfoTooltip,
                onPressed: () => showReminderGuideDialog(
                  context,
                  reminderColor: AppThemeHelper.buttonPrimary(context),
                ),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: AppThemeHelper.buttonPrimary(context),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppThemeHelper.buttonPrimary(
                    context,
                  ).withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppThemeHelper.textSecondary(context),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppThemeHelper.border(
                    context,
                  ).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemeHelper.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, String eventId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: AppThemeHelper.background(context)),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _addCustomReminder(context, eventId),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(AppTexts.addReminder),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeHelper.buttonPrimary(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReminderEntity r) async {
    await showAppDialog(
      context: context,
      type: AppDialogType.delete,
      onConfirm: () {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final controller = ReminderController.to;
            if (r.isDefault) {
              await controller.ignoreDefaultReminder(r.eventId, r);
            } else {
              await controller.applyReminderChange(
                action: ReminderAction.remove,
                eventId: r.eventId,
                reminder: r,
              );
            }
            if (Get.context != null && Get.context!.mounted) {
              AppSnackBars.successSnackBar(
                title: AppTexts.success,
                message: AppTexts.reminderDeletedSuccessfully,
              );
            }
          } catch (error) {
            _showValidationError(error);
          }
        });
      },
      onCancel: () {},
    );
  }

  void _editReminder(BuildContext context, ReminderEntity r) {
    if (!r.canEdit) return;
    if (!r.reminderTime.isAfter(DateTime.now())) {
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.reminderAlreadyPassed,
      );
      return;
    }
    final eventStart = event.startDateTimeSafe;
    if (eventStart == null) {
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.anUnexpectedErrorOccurred,
      );
      return;
    }

    ReminderType type = r.type;
    final formKey = GlobalKey<FormState>();
    final valueCtrl = TextEditingController(text: r.value.toString());
    final reminderColor = AppThemeHelper.buttonPrimary(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Theme(
          data: buildReminderDialogTheme(ctx, reminderColor: reminderColor),
          child: AlertDialog(
            title: buildReminderDialogTitle(
              ctx,
              AppTexts.editReminder,
              reminderColor: reminderColor,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildReminderDialogDescriptionCard(
                      ctx,
                      reminderColor: reminderColor,
                    ),
                    const SizedBox(height: 16),
                    buildReminderTypeDropdown(
                      ctx,
                      value: type,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    buildReminderValueField(
                      ctx,
                      controller: valueCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    buildReminderPreviewCard(
                      ctx,
                      type: type,
                      valueText: valueCtrl.text,
                      reminderColor: reminderColor,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final value = int.parse(valueCtrl.text);
                  try {
                    ReminderEntity.validateCustom(
                      type: type,
                      value: value,
                      existingReminders: ReminderController.to.getReminders(
                        event.id.toString(),
                      ),
                      editingReminderId: r.id,
                      eventStart: eventStart,
                    );
                  } catch (error) {
                    _showValidationError(error);
                    return;
                  }

                  final updated = r.copyWith(
                    id: ReminderEntity.customId(
                      event.id.toString(),
                      type,
                      value,
                    ),
                    type: type,
                    value: value,
                    reminderTime: ReminderEntity.calculateTime(
                      eventStart,
                      type,
                      value,
                    ),
                  );
                  Navigator.of(ctx).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    try {
                      await ReminderController.to.applyReminderChange(
                        action: ReminderAction.update,
                        eventId: event.id.toString(),
                        reminder: updated,
                        previousId: r.id,
                      );
                      if (Get.context != null && Get.context!.mounted) {
                        AppSnackBars.successSnackBar(
                          title: AppTexts.success,
                          message: AppTexts.reminderUpdatedSuccessfully,
                        );
                      }
                    } catch (error) {
                      _showValidationError(error);
                    }
                  });
                },
                child: Text(AppTexts.done),
              ),
            ],
          ),
        ),
      ),
    ).then(
      (_) => Future.delayed(
        const Duration(milliseconds: 400),
        () => valueCtrl.dispose(),
      ),
    );
  }

  void _addCustomReminder(BuildContext context, String eventId) {
    final eventStart = event.startDateTimeSafe;
    if (eventStart == null) {
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.anUnexpectedErrorOccurred,
      );
      return;
    }

    ReminderType type = ReminderType.minute;
    final formKey = GlobalKey<FormState>();
    final valueCtrl = TextEditingController();
    final reminderColor = AppThemeHelper.buttonPrimary(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Theme(
          data: buildReminderDialogTheme(ctx, reminderColor: reminderColor),
          child: AlertDialog(
            title: buildReminderDialogTitle(
              ctx,
              AppTexts.addReminder,
              reminderColor: reminderColor,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildReminderDialogDescriptionCard(
                      ctx,
                      reminderColor: reminderColor,
                    ),
                    const SizedBox(height: 16),
                    buildReminderTypeDropdown(
                      ctx,
                      value: type,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    buildReminderValueField(
                      ctx,
                      controller: valueCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    buildReminderPreviewCard(
                      ctx,
                      type: type,
                      valueText: valueCtrl.text,
                      reminderColor: reminderColor,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final value = int.parse(valueCtrl.text);

                  ReminderEntity newReminder;
                  try {
                    newReminder = ReminderEntity.createCustom(
                      eventId,
                      type,
                      value,
                      eventStart,
                      existingReminders: ReminderController.to.getReminders(
                        eventId,
                      ),
                    );
                  } catch (error) {
                    _showValidationError(error);
                    return;
                  }

                  Navigator.of(ctx).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    try {
                      await ReminderController.to.applyReminderChange(
                        action: ReminderAction.add,
                        eventId: eventId,
                        reminder: newReminder,
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
                child: Text(AppTexts.addReminder),
              ),
            ],
          ),
        ),
      ),
    ).then(
      (_) => Future.delayed(
        const Duration(milliseconds: 400),
        () => valueCtrl.dispose(),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final isPast = reminder.reminderTime.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StreamBuilder<DateTime>(
        stream: ReminderController.to.ticker,
        builder: (_, snapshot) {
          final now = snapshot.data ?? DateTime.now();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppThemeHelper.whiteBlack(context).withValues(alpha: 0.06)
                  : AppThemeHelper.border(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppThemeHelper.border(context),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isPast ? AppColors.red : AppColors.green)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 22,
                    color: isPast ? AppColors.red : AppColors.green,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ReminderController.to.formatReminderLabel(reminder),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ReminderController.to.formatRemainingCountdown(
                          reminder.reminderTime,
                          now: now,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: isPast ? AppColors.red : AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateLocalizationHelper.formatCompactDateTime(
                          reminder.reminderTime,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeHelper.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!reminder.isBackend) _buildActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // تذكير انتهى وقته لا يُعدَّل (يمكن حذفه فقط)
        if (reminder.canEdit && reminder.reminderTime.isAfter(DateTime.now()))
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppThemeHelper.buttonPrimary(context),
            ),
            onPressed: onEdit,
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          ),
        if (reminder.canDelete)
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppThemeHelper.red(context),
            ),
            onPressed: onDelete,
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

/// بوتوم شيت يعرض كل التنبيهات المجدولة لجميع الأحداث مع وقت الإطلاق وتفاصيل الحدث
class ScheduledAlertsSheet extends StatelessWidget {
  const ScheduledAlertsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final ctrl = ReminderController.to;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppThemeHelper.border(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppThemeHelper.buttonPrimary(context),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppTexts.scheduledAlerts,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppThemeHelper.whiteBlack(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppThemeHelper.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppTexts.alertAt} • ${AppTexts.reminders}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ctrl = ReminderController.to;
                        final ok = await ctrl.scheduleTestAlarm();
                        if (context.mounted) {
                          if (ok) {
                            AppSnackBars.successSnackBar(
                              title: AppTexts.testAlert,
                              message: AppTexts.testAlertInSeconds.replaceFirst(
                                '%s',
                                '${ReminderController.testAlarmDelaySeconds}',
                              ),
                            );
                          } else {
                            AppSnackBars.warningSnackBar(
                              title: AppTexts.testAlert,
                              message: AppTexts.noEventToTestAlert,
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.notifications_active_rounded,
                        size: 20,
                        color: AppThemeHelper.buttonPrimary(context),
                      ),
                      label: Text(AppTexts.testAlert),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppThemeHelper.buttonPrimary(context),
                        side: BorderSide(
                          color: AppThemeHelper.buttonPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final all = ctrl.getAllScheduledRemindersSorted();
                final now = DateTime.now();
                final upcoming = all.where(
                  (e) => !e.reminder.reminderTime.isBefore(now),
                );
                final past = all.where(
                  (e) => e.reminder.reminderTime.isBefore(now),
                );

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: AppThemeHelper.textSecondary(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTexts.noReminder,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemeHelper.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _sectionTitle(
                        context,
                        AppTexts.upcomingReminders,
                        upcoming.length,
                        AppColors.green,
                      ),
                      ...upcoming.map((e) => _ScheduledAlertTile(info: e)),
                      const SizedBox(height: 20),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionTitle(
                        context,
                        AppTexts.pastReminders,
                        past.length,
                        AppColors.red,
                      ),
                      ...past.map((e) => _ScheduledAlertTile(info: e)),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledAlertTile extends StatelessWidget {
  final ScheduledReminderInfo info;

  const _ScheduledAlertTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final r = info.reminder;
    final event = info.event;
    final isPast = r.reminderTime.isBefore(DateTime.now());
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppThemeHelper.whiteBlack(context).withValues(alpha: 0.06)
              : AppThemeHelper.border(context).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeHelper.border(context), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isPast ? AppColors.red : AppColors.green).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.alarm_rounded,
                size: 20,
                color: isPast ? AppColors.red : AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event?.name ?? '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppThemeHelper.whiteBlack(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ReminderController.to.formatReminderLabel(r),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppTexts.alertAt} ${DateLocalizationHelper.formatCompactDateTime(r.reminderTime)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
