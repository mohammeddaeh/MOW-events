import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';
import 'package:mow_events/features/event/domin/entities/event_entity.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';

class EventModel extends EventEntity {
  EventModel({
    required super.id,
    required super.name,
    required super.location,
    required super.description,
    required super.startDate,
    required super.endDate,
    required super.startTime,
    required super.endTime,
    required super.status,
    super.category,
    required super.isPublic,
    required super.isPrivate,
    required super.rawReminders,
    required super.reminders,
    required super.createdAt,
    required super.userCurrentInMembers,
    required super.members,
    super.membersDetails,
    super.canShowAcceptReject,
    super.userId,
    super.alarmTimeIso,
    super.isAlarmEnabled,
    super.snoozeDurationMinutes,
  });
  factory EventModel.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, [int defaultVal = 0]) => value == null
        ? defaultVal
        : int.tryParse(value.toString()) ?? defaultVal;
    String safeString(dynamic value, [String defaultVal = ""]) =>
        value?.toString() ?? defaultVal;
    bool safeBool(dynamic value) => value == null
        ? false
        : (value is bool
            ? value
            : (value is int ? value == 1 : value.toString() == '1'));
    List<int> safeMembers(dynamic list) => list == null
        ? []
        : (list as List)
              .map((e) => e is Map ? safeInt(e['id']) : safeInt(e))
              .where((id) => id > 0)
              .toList();

    // تحليل rejected_members: خريطة سبب الرفض + قائمة الأعضاء المرفوضين كاملةً
    final rejectedDescMap = <int, String>{};
    final rejectedMembersList = <EventMemberDisplay>[];
    final rejectedRaw = json["rejected_members"];
    if (rejectedRaw is List) {
      for (final r in rejectedRaw) {
        if (r is Map) {
          final rid = safeInt(r['id']);
          final desc = r['description_reject']?.toString().trim() ?? '';
          if (rid > 0 && desc.isNotEmpty) rejectedDescMap[rid] = desc;
          if (rid > 0) {
            final normalized = Map<String, dynamic>.from(r);
            normalized['status'] = 'reject';
            final m = EventMemberDisplay.fromJson(normalized);
            rejectedMembersList.add(
              desc.isNotEmpty ? m.copyWith(descriptionReject: desc) : m,
            );
          }
        }
      }
    }

    List<EventMemberDisplay> parseMembersDetails(dynamic list) {
      if (list == null || list is! List) return [];
      final result = list
          .whereType<Map>()
          .map((e) {
            final m = EventMemberDisplay.fromJson(Map<String, dynamic>.from(e));
            if (m.id > 0 &&
                m.status == 'reject' &&
                m.descriptionReject == null &&
                rejectedDescMap.containsKey(m.id)) {
              return m.copyWith(descriptionReject: rejectedDescMap[m.id]);
            }
            return m;
          })
          .where((m) => m.id > 0)
          .toList();
      // دمج المرفوضين غير الموجودين في قائمة الأعضاء الرئيسية
      final existingIds = result.map((m) => m.id).toSet();
      for (final rm in rejectedMembersList) {
        if (!existingIds.contains(rm.id)) result.add(rm);
      }
      return result;
    }
    List<ReminderEntity> parseReminders(
      dynamic jsonReminders, {
      required int eventId,
      required DateTime? eventStart,
    }) {
      if (jsonReminders == null) return [];
      return (jsonReminders as List)
          .map((e) {
            try {
              if (e is! Map) return null;
              final normalized = Map<String, dynamic>.from(e);
              normalized.putIfAbsent('event_id', () => eventId.toString());
              final reminderTimeRaw =
                  normalized['reminder'] ??
                  normalized['reminder_time'] ??
                  normalized['reminder_date'];
              if (reminderTimeRaw == null && eventStart != null) {
                final typeString =
                    (normalized['reminder_type'] ?? normalized['type'] ?? 'day')
                        .toString();
                final type = ReminderTypeExt.fromString(typeString);
                final value =
                    int.tryParse((normalized['value'] ?? '0').toString()) ?? 0;
                normalized['reminder'] = ReminderEntity.calculateTime(
                  eventStart,
                  type,
                  value,
                ).toIso8601String();
              }
              return ReminderEntity.fromJson(normalized);
            } catch (_) {
              return null;
            }
          })
          .whereType<ReminderEntity>()
          .toList();
    }

    final parsedId = safeInt(json["id"]);
    var startDateRaw = safeString(json["start_date"]);
    var startTimeRaw = safeString(json['start_time'], '00:00:00');
    var endDateRaw = safeString(json["end_date"]);
    var endTimeRaw = safeString(json['end_time'], '');

    if ((startDateRaw.contains(' ') || startDateRaw.contains('T')) &&
        (startTimeRaw.isEmpty || startTimeRaw == '00:00:00')) {
      final parts = startDateRaw.split(RegExp(r'[ T]'));
      if (parts.isNotEmpty) startDateRaw = parts.first;
      if (parts.length > 1) startTimeRaw = parts.sublist(1).join(' ');
    }

    if (endDateRaw.isEmpty) {
      endDateRaw = startDateRaw;
    }
    if (endTimeRaw.isEmpty) {
      endTimeRaw = endDateRaw == startDateRaw && startTimeRaw.isNotEmpty
          ? startTimeRaw
          : '23:59:59';
    }

    DateTime? parsedStart;
    try {
      parsedStart = EventDateTimeHelper.combine(startDateRaw, startTimeRaw);
    } catch (_) {
      parsedStart = null;
    }

    CategoryModel? parseCategory() {
      final rawCategory = json["category"];
      if (rawCategory is Map) {
        try {
          final model = CategoryModel.fromJson(
            Map<String, dynamic>.from(rawCategory),
          );
          if ((model.id ?? 0) > 0) return model;
        } catch (_) {}
      }

      final categoryIdRaw =
          json["category_id"] ?? json["categoryId"] ?? json["cat_id"];
      final categoryId = safeInt(categoryIdRaw, 0);
      if (categoryId <= 0) return null;
      return CategoryModel(
        id: categoryId,
        name: safeString(
          json["category_name"] ?? json["categoryName"] ?? '',
        ),
        color: safeString(json["category_color"] ?? '#000000'),
        description: safeString(json["category_description"] ?? ''),
      );
    }

    final parsedIsPublic = safeInt(json["is_public"]);
    final parsedIsPrivate = safeInt(json["is_private"]);
    final parsedCategory = parseCategory();
    final effectiveCategory = parsedIsPrivate == 1 ? null : parsedCategory;

    return EventModel(
      id: parsedId,
      category: effectiveCategory,
      name: safeString(json["name"]),
      location: safeString(json["location"]),
      description: safeString(json["description"]),
      startDate: startDateRaw,
      endDate: endDateRaw,
      startTime: startTimeRaw,
      endTime: endTimeRaw,
      status: safeString(json["status"]),
      isPublic: parsedIsPublic,
      isPrivate: parsedIsPrivate,
      rawReminders: List<String>.from(json["reminders"] ?? []),
      reminders: parseReminders(
        json["reminders_type"] ?? json["reminders"],
        eventId: parsedId,
        eventStart: parsedStart,
      ),

      createdAt: safeString(json["created_at"]),
      userCurrentInMembers: safeBool(json["user_current_in_members"]),
      members: safeMembers(json["members"]),
      membersDetails: parseMembersDetails(json["members"]),
      canShowAcceptReject: safeBool(json["can_show_accept_reject"]),
      userId: () {
        if (json["user_id"] != null) return safeInt(json["user_id"]);
        if (json["created_by"] != null) return safeInt(json["created_by"]);
        final user = json["user"];
        if (user is Map && user["id"] != null) return safeInt(user["id"]);
        return null;
      }(),
      alarmTimeIso: json["alarm_time_iso"]?.toString(),
      isAlarmEnabled: json["is_alarm_enabled"] == null
          ? false
          : (json["is_alarm_enabled"] is bool
                ? json["is_alarm_enabled"] as bool
                : safeBool(json["is_alarm_enabled"])),
      snoozeDurationMinutes: () {
        final v = json["snooze_duration_minutes"];
        if (v == null) return 10;
        final n = int.tryParse(v.toString());
        if (n == null || n < 1) return 10;
        return n.clamp(1, 120);
      }(),
    );
  }
}

extension EventDateTimeSafe on EventModel {
  DateTime? get startDateTimeSafe {
    try {
      return EventDateTimeHelper.combine(startDate, startTime);
    } catch (_) {
      return null;
    }
  }

  DateTime? get endDateTimeSafe {
    try {
      return EventDateTimeHelper.combine(endDate, endTime);
    } catch (_) {
      return null;
    }
  }

  String get formattedStartDateSafe => startDateTimeSafe != null
      ? EventDateTimeHelper.formatDate(startDateTimeSafe!)
      : startDate;

  String get formattedEndDateSafe => endDateTimeSafe != null
      ? EventDateTimeHelper.formatDate(endDateTimeSafe!)
      : endDate;

  String get formattedStartTimeSafe => startDateTimeSafe != null
      ? DateLocalizationHelper.formatTime(startDateTimeSafe!)
      : startTime;

  String get formattedEndTimeSafe => endDateTimeSafe != null
      ? DateLocalizationHelper.formatTime(endDateTimeSafe!)
      : endTime;

  /// وقت منبّه ملء الشاشة: [alarmTimeIso] إن وُجد وإلا موعد بداية الحدث.
  DateTime? get effectiveNativeAlarmTime {
    if (alarmTimeIso != null && alarmTimeIso!.trim().isNotEmpty) {
      try {
        return DateTime.parse(alarmTimeIso!);
      } catch (_) {}
    }
    return startDateTimeSafe;
  }
}

extension EventJson on EventModel {
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "category": category != null
          ? {
              "id": category!.id,
              "name": category!.name,
              "color": category!.color,
              "description": category!.description,
            }
          : null,

      "name": name,
      "location": location,
      "description": description,
      "start_date": startDate,
      "end_date": endDate,
      "start_time": startTime,
      "end_time": endTime,
      "status": status,
      "is_public": isPublic,
      "is_private": isPrivate,
      "reminders": rawReminders,
      "reminders_type": reminders
          .map((r) => {"reminder_type": r.type.name, "value": r.value})
          .toList(),
      "created_at": createdAt,
      "user_current_in_members": userCurrentInMembers ? 1 : 0,
      "can_show_accept_reject": canShowAcceptReject ? 1 : 0,
      "members": membersDetails.isNotEmpty
          ? membersDetails
              .map((m) => {
                    "id": m.id,
                    "first_name": m.firstName,
                    "last_name": m.lastName,
                    if (m.image != null) "image": m.image,
                    if (m.departmentName != null)
                      "department": {"name": m.departmentName, "is_manager_department": m.isManager},
                    "is_admin": m.isAdmin ? 1 : 0,
                    "status": m.status,
                  })
              .toList()
          : members.map((m) => {"id": m}).toList(),
      if (alarmTimeIso != null) "alarm_time_iso": alarmTimeIso,
      "is_alarm_enabled": isAlarmEnabled ? 1 : 0,
      "snooze_duration_minutes": snoozeDurationMinutes,
    };
  }
}

extension EventForm on EventModel {
  Map<String, String> toForm() {
    final map = <String, String>{
      'name': name,
      'location': location,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'description': description,
      'is_public': isPublic.toString(),
      'is_private': isPrivate.toString(),
      'user_current_in_members': userCurrentInMembers ? '1' : '0',
    };
    if (category != null) {
      map['category_id'] = category!.id.toString();
    }
    for (int i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final typeName = r.type.name;
      map['reminders[$i][type]'] = typeName;
      map['reminders[$i][value]'] = r.value.toString();
    }

    for (int i = 0; i < members.length; i++) {
      map['members[$i]'] = members[i].toString();
    }

    return map;
  }
}

extension EventCopyWith on EventModel {
  EventModel copyWith({
    int? id,
    int? userId,
    CategoryModel? category,
    String? name,
    String? location,
    String? description,
    String? startDate,
    String? endDate,
    String? startTime,
    String? endTime,
    String? status,
    int? isPublic,
    int? isPrivate,
    List<String>? rawReminders,
    List<ReminderEntity>? reminders,
    String? createdAt,
    bool? userCurrentInMembers,
    List<int>? members,
    List<EventMemberDisplay>? membersDetails,
    bool? canShowAcceptReject,
    String? alarmTimeIso,
    bool? isAlarmEnabled,
    int? snoozeDurationMinutes,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      isPrivate: isPrivate ?? this.isPrivate,
      rawReminders: rawReminders ?? this.rawReminders,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
      userCurrentInMembers: userCurrentInMembers ?? this.userCurrentInMembers,
      members: members ?? this.members,
      membersDetails: membersDetails ?? this.membersDetails,
      canShowAcceptReject: canShowAcceptReject ?? this.canShowAcceptReject,
      alarmTimeIso: alarmTimeIso ?? this.alarmTimeIso,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
    );
  }
}
