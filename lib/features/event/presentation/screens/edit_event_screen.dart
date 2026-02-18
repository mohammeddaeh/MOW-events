import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/edit_event_controller.dart';

class EditEventScreen extends GetView<EditEventController> {
  const EditEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.editEvent), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildDateTimeCard(context),
            const SizedBox(height: 24),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: AppTexts.eventName,
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppTexts.description,
                prefixIcon: Icon(Icons.description),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.locationController,
              decoration: InputDecoration(
                labelText: AppTexts.theSite,
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.timeAndDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppDatePicker(
              label: AppTexts.startDate,
              initialValue: controller.selectedStartDate.value,
              onDatePicked: (date) {
                controller.selectedStartDate.value = date;
              },
            ),

            SizedBox(height: 12),

            AppDatePicker(
              label: AppTexts.endDate,
              initialValue: controller.selectedEndDate.value,
              onDatePicked: (date) {
                controller.selectedEndDate.value = date;
              },
            ),

            const Divider(height: 32),
            AdaptiveFormField(
              controller: controller.startTimeController,
              type: AdaptiveFieldType.time,
              label: AppTexts.startTime,
              onTimeSelected: (t) => controller.selectedStartTime.value = t,
            ),

            const SizedBox(height: 16),

            AdaptiveFormField(
              controller: controller.endTimeController,
              type: AdaptiveFieldType.time,
              label: AppTexts.endTime,
              onTimeSelected: (t) => controller.selectedEndTime.value = t,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Obx(
      () => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.updateEvent,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(AppTexts.updateEvent, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
