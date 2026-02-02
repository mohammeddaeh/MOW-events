import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

class EventValidator {
  static void validate(EventModel event) {
    if (event.name.trim().isEmpty) {
      throw ArgumentError('Event name is required');
    }

    if (event.description.trim().isEmpty) {
      throw ArgumentError('Event description is required');
    }

    final categoryId = event.category?.id;
    if (categoryId != null && categoryId <= 0) {
      throw ArgumentError('Invalid category ID');
    }

    if (event.members.any((id) => id <= 0)) {
      throw ArgumentError('Invalid member ID');
    }
  }

  static void validateRequiredFields({
    required String name,
    required String location,
    required String description,
    required DateTime? startDate,
    required DateTime? endDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (name.trim().isEmpty) {
      throw Exception(AppTexts.eventNameRequired);
    }
    if (location.trim().isEmpty) {
      throw Exception(AppTexts.locationRequired);
    }
    if (description.trim().isEmpty) {
      throw Exception(AppTexts.descriptionRequired);
    }

    if (startDate == null ||
        endDate == null ||
        startTime == null ||
        endTime == null) {
      throw Exception(AppTexts.pleaseSelectAStartAndEndDateAndTime);
    }
  }

  static void validateDateTimeLogic({
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      throw Exception(AppTexts.theEndDateAndTimeMustBeAfterTheStartDate);
    }
  }
}
