import 'dart:convert';

class UserRegistrationData {
  final String? registerStatus;
  final String? registerDescriptionStatus;

  const UserRegistrationData({
    this.registerStatus,
    this.registerDescriptionStatus,
  });

  static const _descriptionFieldKeys = [
    'register_description_status',
    'registerDescriptionStatus',
    'rejection_reason',
    'rejectionReason',
    'reject_reason',
    'reason',
    'description',
    'message',
    'admin_message',
    'admin_note',
    'note',
    'comments',
    'comment',
  ];

  factory UserRegistrationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserRegistrationData();

    final status = json['register_status']?.toString().trim() ??
        json['registerStatus']?.toString().trim();

    String? description;
    for (final key in _descriptionFieldKeys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        description = value;
        break;
      }
    }

    return UserRegistrationData(
      registerStatus: status?.isEmpty == true ? null : status,
      registerDescriptionStatus:
          description?.isEmpty == true ? null : description,
    );
  }

  /// يجمع حقول حالة التسجيل من استجابة المستخدم (تسجيل دخول / تسجيل / ملف محلي).
  static UserRegistrationData resolveFromUserJson(Map<String, dynamic> json) {
    UserRegistrationData? fromMap(Map<String, dynamic>? map) {
      if (map == null || map.isEmpty) return null;
      final data = UserRegistrationData.fromJson(map);
      if (data.registerStatus != null ||
          data.registerDescriptionStatus != null) {
        return data;
      }
      return null;
    }

    final nested = fromMap(parseFcmPayload(json['data_registration_user']));
    if (nested != null) return nested;

    for (final key in [
      'registration_user',
      'registration',
      'registration_data',
    ]) {
      final alt = fromMap(parseFcmPayload(json[key]));
      if (alt != null) return alt;
    }

    final rootStatus = json['register_status']?.toString().trim();
    if (rootStatus != null && rootStatus.isNotEmpty) {
      return UserRegistrationData.fromJson({
        'register_status': rootStatus,
        'register_description_status': json['register_description_status'],
      });
    }

    if (_readAwaitingRegistrationFlag(json)) {
      return const UserRegistrationData(registerStatus: 'pending');
    }

    return const UserRegistrationData();
  }

  static bool _readAwaitingRegistrationFlag(Map<String, dynamic> json) {
    for (final key in [
      'is_register',
      'is_registration_pending',
      'awaiting_registration_approval',
      'registration_pending',
    ]) {
      final value = json[key];
      if (value == true || value == 1 || value == '1') return true;
      if (value is String && value.toLowerCase().trim() == 'pending') {
        return true;
      }
    }

    final accountStatus =
        json['account_status']?.toString().toLowerCase().trim() ?? '';
    return accountStatus == 'pending' ||
        accountStatus == 'awaiting_approval' ||
        accountStatus == 'awaiting_registration';
  }

  /// يفكّ `data_registration_user` من FCM (Map أو JSON string).
  static Map<String, dynamic>? parseFcmPayload(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is! String) return null;

    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        if (decoded is String) {
          trimmed = decoded.trim();
          continue;
        }
      } catch (_) {
        if (trimmed.contains(r'\"')) {
          trimmed = trimmed.replaceAll(r'\"', '"');
          continue;
        }
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          trimmed = trimmed.replaceAll("'", '"');
          continue;
        }
      }
      break;
    }

    return null;
  }

  static bool isRejectionStatus(String? status) {
    final normalized = status?.toLowerCase().trim() ?? '';
    if (normalized.isEmpty) return false;

    const rejectionValues = {
      'rejected',
      'reject',
      'refused',
      'denied',
      'declined',
      'cancelled',
      'canceled',
      '2',
    };
    return rejectionValues.contains(normalized);
  }

  static UserRegistrationData? fromFcmData(Map<String, dynamic>? fcmData) {
    if (fcmData == null) return null;

    for (final map in collectRegistrationMaps(
      data: fcmData,
      extraRaw: const [],
    )) {
      final reg = UserRegistrationData.fromJson(map);
      if (reg.registerStatus != null || reg.registerDescriptionStatus != null) {
        return reg;
      }
    }

    return null;
  }

  /// يجمع كل خرائط حالة التسجيل من FCM/API (متداخلة أو JSON نصية).
  static List<Map<String, dynamic>> collectRegistrationMaps({
    Map<String, dynamic>? data,
    List<String?> extraRaw = const [],
  }) {
    final maps = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addMap(Map<String, dynamic>? map) {
      if (map == null || map.isEmpty) return;
      final key = map.entries
          .map((e) => '${e.key}=${e.value}')
          .join('|');
      if (seen.add(key)) {
        maps.add(map);
      }
    }

    void ingest(dynamic raw) {
      final parsed = parseFcmPayload(raw);
      if (parsed != null) {
        addMap(parsed);
        return;
      }
      if (raw is Map) {
        addMap(Map<String, dynamic>.from(raw));
      }
    }

    if (data != null) {
      addMap(Map<String, dynamic>.from(data));
      ingest(data['data_registration_user']);
      for (final key in [
        'registration_user',
        'registration',
        'registration_data',
        'payload',
      ]) {
        ingest(data[key]);
      }
      for (final value in data.values) {
        ingest(value);
      }
    }

    for (final raw in extraRaw) {
      ingest(raw);
    }

    return maps;
  }

  /// سبب الرفض من `data_registration_user` كما يرسله Laravel مع FCM.
  static String? extractFromDataRegistrationUser(Map<String, dynamic>? data) {
    if (data == null) return null;

    final parsed = parseFcmPayload(data['data_registration_user']);
    if (parsed != null) {
      final fromNested = rejectionReasonFromRegistrationMap(parsed);
      if (fromNested != null) return fromNested;
    }

    final fromFlattened = _extractFromFlattenedKeys(data);
    if (fromFlattened != null) return fromFlattened;

    return rejectionReasonFromRegistrationMap(data);
  }

  static String? rejectionReasonFromRegistrationMap(
    Map<String, dynamic> map,
  ) {
    final reg = UserRegistrationData.fromJson(map);

    final reason = reg.displayRejectionReason;
    if (reason != null && reason.isNotEmpty) return reason;

    final description = reg.registerDescriptionStatus?.trim();
    if (description == null ||
        description.isEmpty ||
        isTechnicalToken(description)) {
      return null;
    }

    if (isRejectionStatus(description)) return null;
    if (reg.normalizedStatus.isNotEmpty &&
        description.toLowerCase() == reg.normalizedStatus) {
      return null;
    }

    return description;
  }

  static String? _extractFromFlattenedKeys(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (!key.contains('register_description') &&
          !key.contains('rejection') &&
          !key.endsWith('reason') &&
          !key.endsWith('message')) {
        continue;
      }

      final normalized = normalizeReasonText(entry.value?.toString());
      if (normalized != null) return normalized;
    }
    return null;
  }

  /// سبب الرفض من بيانات الإشعار (FCM أو قائمة الإشعارات).
  static String? extractRejectionReason({
    Map<String, dynamic>? data,
    String? notificationTitle,
    String? notificationBody,
  }) {
    final fromRegistrationPayload = extractFromDataRegistrationUser(data);
    if (fromRegistrationPayload != null) {
      return fromRegistrationPayload;
    }

    final candidates = <String?>[];

    for (final map in collectRegistrationMaps(
      data: data,
      extraRaw: [notificationTitle, notificationBody],
    )) {
      final reg = UserRegistrationData.fromJson(map);
      candidates.add(reg.displayRejectionReason);
      candidates.add(reg.registerDescriptionStatus);
      for (final key in _descriptionFieldKeys) {
        candidates.add(map[key]?.toString());
      }
    }

    if (data != null) {
      for (final key in _descriptionFieldKeys) {
        candidates.add(data[key]?.toString());
      }
    }

    candidates.addAll([notificationBody, notificationTitle]);

    for (final candidate in candidates) {
      final normalized = normalizeReasonText(candidate);
      if (normalized != null) return normalized;
    }

    return null;
  }

  /// يحوّل نصّ السبب إلى نص عرض؛ يتجاهل المفاتيح التقنية ويفك JSON إن وُجد.
  static String? normalizeReasonText(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    final parsed = parseFcmPayload(text);
    if (parsed != null) {
      final fromPayload = UserRegistrationData.fromJson(parsed).displayRejectionReason;
      if (fromPayload != null && fromPayload.isNotEmpty) {
        return fromPayload;
      }
    }

    if (isTechnicalToken(text)) return null;
    if (text.startsWith('{') || text.startsWith('[')) return null;

    return text;
  }

  static bool isTechnicalToken(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) return false;
    if (trimmed.contains(' ') && trimmed.length > 12) return false;

    final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    const tokens = {
      'accept_user_registration',
      'reject_user_registration',
      'acceptuserregistration',
      'rejectuserregistration',
      'data_registration_user',
      'register_status',
      'notification_type',
      'type',
      'approved',
      'rejected',
      'pending',
      'accept',
      'reject',
      'registrationrejecteddefaultreason',
      'registrationrejectedtitle',
      'registrationapprovedmessage',
      'registrationapprovedtitle',
    };

    if (tokens.contains(normalized)) return true;
    if (normalized.contains('data_registration_user')) return true;
    if (normalized.contains('accept_user_registration')) return true;
    if (normalized.contains('reject_user_registration')) return true;

    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(normalized) &&
        normalized.contains('_');
  }

  static bool hasFcmPayload(Map<String, dynamic>? fcmData) {
    return fromFcmData(fcmData) != null;
  }

  Map<String, dynamic> toJson() => {
    if (registerStatus != null) 'register_status': registerStatus,
    if (registerDescriptionStatus != null)
      'register_description_status': registerDescriptionStatus,
  };

  String get normalizedStatus => registerStatus?.toLowerCase().trim() ?? '';

  bool get isPending => normalizedStatus == 'pending';

  bool get isRejected => isRejectionStatus(registerStatus);

  bool get isApproved =>
      normalizedStatus == 'approved' || normalizedStatus == 'accept';

  /// سبب الرفض للعرض (يتجاهل JSON كامل إن وُجد بالخطأ في الحقل).
  String? get displayRejectionReason {
    final raw = registerDescriptionStatus?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parsed = parseFcmPayload(raw);
    if (parsed != null) {
      final description =
          parsed['register_description_status']?.toString().trim();
      if (description != null &&
          description.isNotEmpty &&
          !UserRegistrationData.isTechnicalToken(description)) {
        return description;
      }
    }

    if (raw.startsWith('{') || raw.startsWith('[')) return null;

    final statusOnly = normalizedStatus;
    if (statusOnly.isNotEmpty && raw.toLowerCase() == statusOnly) return null;
    if (UserRegistrationData.isTechnicalToken(raw)) return null;

    return raw;
  }

  bool get requiresApproval => isPending || isRejected;
}
