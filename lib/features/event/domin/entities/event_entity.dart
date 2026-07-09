import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';

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

  /// تفاصيل الأعضاء كاملة (تأتي مباشرة في رد API الحدث)
  final List<EventMemberDisplay> membersDetails;

  /// إذا كان true يظهر زرا القبول والرفض للمستخدم الحالي
  final bool canShowAcceptReject;

  /// وقت التنبيه الأصلي (ISO8601). إن كان null يُستخدم موعد بداية الحدث.
  final String? alarmTimeIso;

  /// تفعيل منبّه ملء الشاشة (أندرويد) لهذا الحدث.
  final bool isAlarmEnabled;

  /// مدة الغفوة الافتراضية بالدقائق.
  final int snoozeDurationMinutes;

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
    this.membersDetails = const [],
    this.canShowAcceptReject = false,
    this.userId,
    this.alarmTimeIso,
    this.isAlarmEnabled = false,
    this.snoozeDurationMinutes = 10,
  });
}
