import 'package:mow_events/core/utils/translation/app_texts.dart';

enum ReminderType { day, hour, minute }

extension ReminderTypeExt on ReminderType {
  static ReminderType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'day':
        return ReminderType.day;
      case 'hour':
        return ReminderType.hour;
      case 'minute':
        return ReminderType.minute;
      default:
        return ReminderType.day;
    }
  }

  String get name {
    switch (this) {
      case ReminderType.day:
        return 'day';
      case ReminderType.hour:
        return 'hour';
      case ReminderType.minute:
        return 'minute';
    }
  }

  String get localized {
    switch (this) {
      case ReminderType.day:
        return AppTexts.day;
      case ReminderType.hour:
        return AppTexts.hour;
      case ReminderType.minute:
        return AppTexts.minute;
    }
  }
}

enum ReminderSource { backend, default_, custom }

class ReminderEntity {
  final String id;
  final String eventId;
  final ReminderSource source;
  final ReminderType type;
  final int value;
  final DateTime reminderTime;
  final int alarmId;
  final String? defaultKey;

  ReminderEntity({
    required this.id,
    required this.eventId,
    required this.source,
    required this.type,
    required this.value,
    required this.reminderTime,
    required this.alarmId,
    this.defaultKey,
  });

  factory ReminderEntity.createCustom(
    String eventId,
    ReminderType type,
    int value,
    DateTime eventStart,
  ) {
    final reminderTime = calculateTime(eventStart, type, value);
    return ReminderEntity(
      id: 'custom_${eventId}_${type.name}_$value',
      eventId: eventId,
      source: ReminderSource.custom,
      type: type,
      value: value,
      reminderTime: reminderTime,
      alarmId: DateTime.now().microsecondsSinceEpoch,
    );
  }

  static DateTime calculateTime(DateTime start, ReminderType type, int value) {
    switch (type) {
      case ReminderType.day:
        return start.subtract(Duration(days: value));
      case ReminderType.hour:
        return start.subtract(Duration(hours: value));
      case ReminderType.minute:
        return start.subtract(Duration(minutes: value));
    }
  }

  factory ReminderEntity.fromJson(Map<String, dynamic> json) {
    final sourceStr = json['source'] ?? 'backend';
    final source = sourceStr == 'custom'
        ? ReminderSource.custom
        : sourceStr == 'default'
        ? ReminderSource.default_
        : ReminderSource.backend;

    return ReminderEntity(
      id:
          json['id'] ??
          '${sourceStr}_${json['event_id']}_${json['reminder_type']}_${json['value']}',
      eventId: json['event_id'] ?? '',
      source: source,
      type: ReminderTypeExt.fromString(json['reminder_type'] ?? 'day'),
      value: json['value'] ?? 0,
      reminderTime: DateTime.tryParse(json['reminder'] ?? '') ?? DateTime.now(),
      defaultKey: json['default_key'],
      alarmId: json['alarm_id'] ?? DateTime.now().microsecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'reminder_type': type.name,
    'value': value,
    'reminder': reminderTime.toIso8601String(),
    'alarm_id': alarmId,
    'default_key': defaultKey,
    'source': source == ReminderSource.custom
        ? 'custom'
        : source == ReminderSource.default_
        ? 'default'
        : 'backend',
  };

  ReminderEntity copyWith({
    String? id,
    ReminderType? type,
    int? value,
    DateTime? reminderTime,
    ReminderSource? source,
    int? alarmId,
    String? defaultKey,
  }) {
    return ReminderEntity(
      id: id ?? this.id,
      eventId: eventId,
      type: type ?? this.type,
      value: value ?? this.value,
      reminderTime: reminderTime ?? this.reminderTime,
      source: source ?? this.source,
      alarmId: alarmId ?? this.alarmId,
      defaultKey: defaultKey ?? this.defaultKey,
    );
  }

  bool get isDefault => source == ReminderSource.default_;
  bool get isCustom => source == ReminderSource.custom;
  bool get isBackend => source == ReminderSource.backend;

  bool get canEdit => isCustom;
  bool get canDelete => isCustom || isDefault;
}

class DefaultReminder {
  final ReminderType type;
  final int value;

  DefaultReminder({required this.type, required this.value});

  DefaultReminder copyWith({ReminderType? type, int? value}) {
    return DefaultReminder(type: type ?? this.type, value: value ?? this.value);
  }

  Map<String, dynamic> toJson() => {'reminder_type': type.name, 'value': value};

  factory DefaultReminder.fromJson(Map<String, dynamic> json) {
    return DefaultReminder(
      type: ReminderTypeExt.fromString(json['reminder_type'] ?? 'day'),
      value: json['value'] ?? 0,
    );
  }

  ReminderEntity toReminderEntity(
    String eventId,
    DateTime eventStart, {
    bool isCustom = false,
  }) {
    final reminderTime = ReminderEntity.calculateTime(eventStart, type, value);
    final source = isCustom ? ReminderSource.custom : ReminderSource.default_;
    final id = '${source.name}_${eventId}_${type.name}_$value';
    final key = '${type.name}_$value';

    return ReminderEntity(
      id: id,
      eventId: eventId,
      source: source,
      type: type,
      value: value,
      reminderTime: reminderTime,
      defaultKey: key,

      alarmId: DateTime.now().microsecondsSinceEpoch,
    );
  }
}
