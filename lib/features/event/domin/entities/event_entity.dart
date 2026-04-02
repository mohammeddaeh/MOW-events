import 'package:mow_events/features/category/data/models/category_model.dart';

import 'reminder_entity.dart';

class EventEntity {
  final int id;
  final CategoryModel? category;
  final String name;
  final String location;
  final String description;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String status;

  final int isPublic;
  final int isPrivate;
  final List<String> rawReminders;
  final List<ReminderEntity> reminders;
  final String createdAt;
  final bool userCurrentInMembers;
  final List<int> members;
  final int? userId;

  EventEntity({
    required this.id,
    this.category,
    required this.name,
    required this.location,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.status,

    required this.isPublic,
    required this.isPrivate,
    required this.rawReminders,
    required this.reminders,
    required this.createdAt,
    required this.userCurrentInMembers,
    required this.members,
    this.userId,
  });
}
