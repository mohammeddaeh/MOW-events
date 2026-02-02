import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

import '../../../../core/shared/widgets/dialoge/app_dialog.dart';

class EventRemindersSheet extends StatelessWidget {
  final EventModel event;
  final RxList<ReminderEntity> reminders;
  final DateTime now;

  const EventRemindersSheet({
    super.key,
    required this.event,
    required this.reminders,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final eventId = event.id.toString();

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.blackWhite(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final reminders = this.reminders;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (_, index) {
                    final r = reminders[index];
                    return StreamBuilder<DateTime>(
                      stream: ReminderController.to.ticker,
                      builder: (_, snapshot) {
                        final now = snapshot.data ?? DateTime.now();
                        return ListTile(
                          leading: const Icon(Icons.alarm),
                          title: Text(
                            ReminderController.to.formatReminderLabel(r),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: _buildActions(context, r),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                ReminderController.to.formatRemainingCountdown(
                                  r.reminderTime,
                                  now: now,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: r.reminderTime.isBefore(now)
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd MMM • HH:mm',
                                ).format(r.reminderTime),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
            FloatingActionButton(
              onPressed: () => _addCustomReminder(context, eventId),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildActions(BuildContext context, ReminderEntity r) {
    if (r.isBackend) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (r.canEdit)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editReminder(context, r),
          ),

        if (r.canDelete)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await _confirmDelete(context, r);
            },
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReminderEntity r) async {
    await showAppDialog(
      context: context,
      type: AppDialogType.delete,
      onConfirm: () async {
        final controller = ReminderController.to;

        if (r.isDefault) {
          controller.ignoreDefaultReminder(r.eventId, r);
        } else {
          controller.applyReminderChange(
            action: ReminderAction.remove,
            eventId: r.eventId,
            reminder: r,
          );
        }
      },
      onCancel: () {},
    );
  }

  void _editReminder(BuildContext context, ReminderEntity r) {
    if (!r.canEdit) return;

    ReminderType type = r.type;
    int value = r.value;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppTexts.editReminder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<ReminderType>(
              value: type,
              items: ReminderType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => type = v!,
            ),
            TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => value = int.tryParse(v) ?? value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updated = r.copyWith(
                type: type,
                value: value,
                reminderTime: ReminderEntity.calculateTime(
                  event.startDateTimeSafe!,
                  type,
                  value,
                ),
              );

              ReminderController.to.applyReminderChange(
                action: ReminderAction.update,
                eventId: event.id.toString(),
                reminder: updated,
              );
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addCustomReminder(BuildContext context, String eventId) {
    ReminderType type = ReminderType.minute;
    int value = 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<ReminderType>(
              value: type,
              items: ReminderType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => type = v!,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Value'),
              onChanged: (v) => value = int.tryParse(v) ?? value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newReminder = ReminderEntity.createCustom(
                eventId,
                type,
                value,
                event.startDateTimeSafe!,
              );

              ReminderController.to.applyReminderChange(
                action: ReminderAction.add,
                eventId: eventId,
                reminder: newReminder,
              );
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
