import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

class AddRemindersScreen extends GetView<ReminderController> {
  const AddRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.manageReminders)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final reminders = controller.defaultReminders;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final r = reminders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('${r.type.localized} - ${r.value}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _editDefaultReminder(context, index, r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteDefaultReminder(context, index, r),
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
                    label: Text(
                      AppTexts.addReminder,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppTexts.addReminder),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReminderType>(
                    value: type,
                    items: ReminderType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.localized),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => type = v!,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: AppTexts.value.tr),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppTexts.requiredField.tr;
                      }
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) {
                        return AppTexts.invalidNumber.tr;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(AppTexts.applyTo.tr),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: applyToAllEvents,
                    title: Text(AppTexts.futureEventsOnly.tr),
                    onChanged: (v) => setState(() => applyToAllEvents = v!),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: applyToAllEvents,
                    title: Text(AppTexts.allEvents.tr),
                    onChanged: (v) => setState(() => applyToAllEvents = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(AppTexts.cancel.tr)),
              ElevatedButton(
                child: Text(AppTexts.add.tr),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final value = int.parse(valueController.text);

                  ReminderController.to.addDefaultReminder(
                    DefaultReminder(type: type, value: value),
                    applyToAllEvents: applyToAllEvents,
                  );

                  Get.back();
                  Get.snackbar(
                    AppTexts.success.tr,
                    AppTexts.reminderAddedSuccessfully.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _editDefaultReminder(
    BuildContext context,
    int index,
    DefaultReminder r,
  ) {
    ReminderType type = r.type;
    int value = r.value;
    bool applyToAllEvents = false;
    final controller = TextEditingController(text: value.toString());

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppTexts.editReminder),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ReminderType>(
                  value: type,
                  items: ReminderType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.localized),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: controller,
                  onChanged: (v) => value = int.tryParse(v) ?? value,
                ),
                const SizedBox(height: 16),
                Text(AppTexts.applyEditTo),
                RadioListTile<bool>(
                  value: false,
                  groupValue: applyToAllEvents,
                  title: Text(AppTexts.futureEventsOnly),
                  onChanged: (v) => setState(() => applyToAllEvents = v!),
                ),
                RadioListTile<bool>(
                  value: true,
                  groupValue: applyToAllEvents,
                  title: Text(AppTexts.allEventsContainingThisReminder),
                  onChanged: (v) => setState(() => applyToAllEvents = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(AppTexts.cancel)),
              ElevatedButton(
                onPressed: () {
                  ReminderController.to.updateDefaultReminder(
                    index,
                    type,
                    value,
                    applyToAllEvents: applyToAllEvents,
                  );

                  Get.back();
                  Get.snackbar(
                    AppTexts.success,
                    AppTexts.reminderUpdatedSuccessfully,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text(AppTexts.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteDefaultReminder(
    BuildContext context,
    int index,
    DefaultReminder r,
  ) {
    bool applyToAllEvents = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppTexts.deleteReminder),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppTexts.ifyouAreSureAboutDeleting),
                const SizedBox(height: 16),

                RadioListTile<bool>(
                  value: false,
                  groupValue: applyToAllEvents,
                  title: Text(AppTexts.futureEventsOnly),
                  onChanged: (v) => setState(() => applyToAllEvents = v!),
                ),
                RadioListTile<bool>(
                  value: true,
                  groupValue: applyToAllEvents,
                  title: Text(AppTexts.allEventsContainingThisReminder),
                  onChanged: (v) => setState(() => applyToAllEvents = v!),
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
                onPressed: () {
                  ReminderController.to.removeDefaultReminder(
                    index,
                    applyToAllEvents: applyToAllEvents,
                  );

                  Get.back();
                  Get.snackbar(
                    AppTexts.success,
                    AppTexts.reminderDeletedSuccessfully,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text(AppTexts.delete),
              ),
            ],
          );
        },
      ),
    );
  }
}
