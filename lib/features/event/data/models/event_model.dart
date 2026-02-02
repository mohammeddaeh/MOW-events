import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
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
  });
  factory EventModel.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, [int defaultVal = 0]) => value == null
        ? defaultVal
        : int.tryParse(value.toString()) ?? defaultVal;
    String safeString(dynamic value, [String defaultVal = ""]) =>
        value?.toString() ?? defaultVal;
    bool safeBool(dynamic value) => value == null
        ? false
        : (value is int ? value == 1 : value.toString() == '1');
    List<int> safeMembers(dynamic list) => list == null
        ? []
        : (list as List)
              .map((e) => e is Map ? safeInt(e['id']) : safeInt(e))
              .toList();
    List<ReminderEntity> parseReminders(dynamic jsonReminders) {
      if (jsonReminders == null) return [];
      return (jsonReminders as List)
          .map((e) {
            try {
              return ReminderEntity.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<ReminderEntity>()
          .toList();
    }

    return EventModel(
      id: safeInt(json["id"]),
      category: json["category"] != null
          ? CategoryModel.fromJson(json["category"])
          : null,
      name: safeString(json["name"]),
      location: safeString(json["location"]),
      description: safeString(json["description"]),
      startDate: safeString(json["start_date"]),
      endDate: safeString(json["end_date"]),
      startTime: safeString(json['start_time'], "00:00:00"),
      endTime: safeString(json['end_time'], "00:00:00"),
      status: safeString(json["status"]),
      isPublic: safeInt(json["is_public"]),
      isPrivate: safeInt(json["is_private"]),
      rawReminders: List<String>.from(json["reminders"] ?? []),
      reminders: parseReminders(json["reminders_type"]),

      createdAt: safeString(json["created_at"]),
      userCurrentInMembers: safeBool(json["user_current_in_members"]),
      members: safeMembers(json["members"]),
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
      ? EventDateTimeHelper.formatTime(startDateTimeSafe!)
      : startTime;

  String get formattedEndTimeSafe => endDateTimeSafe != null
      ? EventDateTimeHelper.formatTime(endDateTimeSafe!)
      : endTime;
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
      "members": members.map((m) => {"id": m}).toList(),
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
      map['reminders[$i][reminder_time]'] = r.reminderTime.toIso8601String();
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
  }) {
    print('[EventModel] copyWith -> id: ${id ?? this.id}');

    return EventModel(
      id: id ?? this.id,
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
    );
  }
}
