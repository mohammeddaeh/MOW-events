import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class EditEventController extends GetxController {
  final HomeController homeController;

  EditEventController({required this.homeController});

  late EventModel event;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  final selectedStartDate = DateTime.now().obs;
  final selectedEndDate = DateTime.now().obs;
  final selectedStartTime = const TimeOfDay(hour: 9, minute: 0).obs;
  final selectedEndTime = const TimeOfDay(hour: 10, minute: 0).obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    event = Get.arguments as EventModel;
    _fillForm();
  }

  void _fillForm() {
    nameController.text = event.name;
    descriptionController.text = event.description;
    locationController.text = event.location;

    final start = event.startDateTimeSafe ?? DateTime.now();
    final end =
        event.endDateTimeSafe ?? DateTime.now().add(const Duration(hours: 1));

    selectedStartDate.value = DateTime(start.year, start.month, start.day);
    selectedEndDate.value = DateTime(end.year, end.month, end.day);

    selectedStartTime.value = TimeOfDay(hour: start.hour, minute: start.minute);
    selectedEndTime.value = TimeOfDay(hour: end.hour, minute: end.minute);

    startTimeController.text =
        '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${selectedStartTime.value.minute.toString().padLeft(2, '0')}';
    endTimeController.text =
        '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${selectedEndTime.value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> updateEvent() async {
    if (!validate()) return;

    final updatedEvent = event.copyWith(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      location: locationController.text.trim(),
      startDate: EventDateTimeHelper.formatDate(selectedStartDate.value),
      startTime: EventDateTimeHelper.formatTimeHhMm(selectedStartTime.value),
      endDate: EventDateTimeHelper.formatDate(selectedEndDate.value),
      endTime: EventDateTimeHelper.formatTimeHhMm(selectedEndTime.value),
    );

    isLoading.value = true;
    try {
      await homeController.updateEvent(updatedEvent.id, updatedEvent);
      Get.back();
    } catch (e) {
      Get.snackbar(AppTexts.errorOccurred, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool validate() {
    try {
      EventValidator.validateRequiredFields(
        name: nameController.text,
        location: locationController.text,
        description: descriptionController.text,
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        startTime: selectedStartTime.value,
        endTime: selectedEndTime.value,
      );

      EventValidator.validateDateTimeLogic(
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        startTime: selectedStartTime.value,
        endTime: selectedEndTime.value,
      );

      return true;
    } catch (e) {
      Get.snackbar(AppTexts.error, e.toString());
      return false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.onClose();
  }
}
