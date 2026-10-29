import 'package:mow_events/core/utils/translation/app_texts.dart';

enum ReminderType { day, hours, minute }

extension ReminderTypeExt on ReminderType {
  static ReminderType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'day':
        return ReminderType.day;
      case 'hour':
        return ReminderType.hours;
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
      case ReminderType.hours:
        return 'hour';
      case ReminderType.minute:
        return 'minute';
    }
  }

  String get localized {
    switch (this) {
      case ReminderType.day:
        return AppTexts.day;
      case ReminderType.hours:
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
    DateTime eventStart, {
    Iterable<ReminderEntity> existingReminders = const [],
  }) {
    validateCustom(
      type: type,
      value: value,
      existingReminders: existingReminders,
      eventStart: eventStart,
    );
    final reminderTime = calculateTime(eventStart, type, value);
    return ReminderEntity(
      id: customId(eventId, type, value),
      eventId: eventId,
      source: ReminderSource.custom,
      type: type,
      value: value,
      reminderTime: reminderTime,
      alarmId: DateTime.now().microsecondsSinceEpoch,
    );
  }

  static bool isReservedAtStartReminder(ReminderType type, int value) =>
      type == ReminderType.minute && value == 0;

  /// المعرّف مبني من الوحدة والقيمة — يجب إعادة توليده عند التعديل وإلا
  /// يتصادم مع تذكير جديد بنفس الوحدة والقيمة القديمتين.
  static String customId(String eventId, ReminderType type, int value) =>
      'custom_${eventId}_${type.name}_$value';

  /// [eventStart]: عند تمريره يُرفض التذكير الذي يقع وقته في الماضي (لن يرن أبداً).
  static void validateCustom({
    required ReminderType type,
    required int value,
    Iterable<ReminderEntity> existingReminders = const [],
    String? editingReminderId,
    DateTime? eventStart,
  }) {
    if (value < 0) {
      throw ArgumentError(AppTexts.reminderValueCannotBeNegative);
    }

    if (value == 0) {
      if (isReservedAtStartReminder(type, value)) {
        throw ArgumentError(AppTexts.reminderAtStartReserved);
      }

      throw ArgumentError(AppTexts.mustBeGreaterThanZero);
    }

    if (isReservedAtStartReminder(type, value)) {
      throw ArgumentError(AppTexts.reminderAtStartReserved);
    }

    final hasDuplicate = existingReminders.any(
      (reminder) =>
          reminder.id != editingReminderId &&
          reminder.type == type &&
          reminder.value == value,
    );

    if (hasDuplicate) {
      throw ArgumentError(AppTexts.reminderAlreadyExists);
    }

    if (eventStart != null &&
        !calculateTime(eventStart, type, value).isAfter(DateTime.now())) {
      throw ArgumentError(AppTexts.reminderTimeInPast);
    }
  }

  static DateTime calculateTime(DateTime start, ReminderType type, int value) {
    switch (type) {
      case ReminderType.day:
        return start.subtract(Duration(days: value));
      case ReminderType.hours:
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

    final typeRaw = (json['reminder_type'] ?? json['type'] ?? 'day').toString();
    final valueRaw = int.tryParse((json['value'] ?? 0).toString()) ?? 0;
    final reminderRaw =
        json['reminder'] ?? json['reminder_time'] ?? json['reminder_date'];

    return ReminderEntity(
      id:
          json['id'] ??
          '${sourceStr}_${json['event_id'] ?? json['eventId']}_${typeRaw}_$valueRaw',
      eventId: (json['event_id'] ?? json['eventId'] ?? '').toString(),
      source: source,
      type: ReminderTypeExt.fromString(typeRaw),
      value: valueRaw,
      reminderTime:
          DateTime.tryParse(reminderRaw?.toString() ?? '') ?? DateTime.now(),
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

    final alarmId = (Object.hash(eventId, id) & 0x7FFFFFFF);
    return ReminderEntity(
      id: id,
      eventId: eventId,
      source: source,
      type: type,
      value: value,
      reminderTime: reminderTime,
      defaultKey: key,
      alarmId: alarmId,
    );
  }
}
