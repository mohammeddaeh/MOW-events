import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
import 'package:mow_events/features/notifications/utils/registration_notification_display.dart';

enum NotificationType {
  eventInvitation,
  updateEvent,
  deleteEvent,
  acceptUserRegistration,
  rejectUserRegistration,
}

extension NotificationTypeHelpers on NotificationType {
  bool get isRegistrationApproval =>
      this == NotificationType.acceptUserRegistration ||
      this == NotificationType.rejectUserRegistration;
}

NotificationType? registrationNotificationTypeFromFcmData(
  Map<String, dynamic>? fcmData,
) {
  if (fcmData == null) return null;

  final wireType =
      fcmData['notification_type']?.toString() ??
      fcmData['type']?.toString() ??
      '';
  final wire = wireType.toLowerCase().trim();
  if (wire.contains('reject_user_registration') ||
      wire.contains('rejectuserregistration')) {
    return NotificationType.rejectUserRegistration;
  }
  if (wire.contains('accept_user_registration') ||
      wire.contains('acceptuserregistration')) {
    return NotificationType.acceptUserRegistration;
  }

  final reg = UserRegistrationData.fromFcmData(fcmData);
  if (reg == null) {
    final reason = UserRegistrationData.extractFromDataRegistrationUser(
      fcmData,
    );
    if (reason != null) return NotificationType.rejectUserRegistration;
    return null;
  }
  if (reg.isRejected) return NotificationType.rejectUserRegistration;
  if (reg.isPending) return null;
  if (reg.isApproved) return NotificationType.acceptUserRegistration;

  if (UserRegistrationData.rejectionReasonFromRegistrationMap(fcmData) !=
      null) {
    return NotificationType.rejectUserRegistration;
  }

  return null;
}

extension NotificationTypeExtension on NotificationType {
  /// قيمة الباكند/FCM (لا تستخدم [Enum.name] فهو camelCase).
  String get wireValue {
    switch (this) {
      case NotificationType.eventInvitation:
        return 'event_invitation';
      case NotificationType.updateEvent:
        return 'update_event';
      case NotificationType.deleteEvent:
        return 'delete_event';
      case NotificationType.acceptUserRegistration:
        return 'accept_user_registration';
      case NotificationType.rejectUserRegistration:
        return 'reject_user_registration';
    }
  }

  static NotificationType fromString(String? value) {
    final normalized = _normalizeTypeKey(value ?? '');
    switch (normalized) {
      case 'event_invitation':
      case 'invite_event':
      case 'event_invite':
      case 'new_event':
      case 'create_event':
        return NotificationType.eventInvitation;
      case 'update_event':
      case 'event_update':
      case 'event_updated':
      case 'updated_event':
      case 'edit_event':
        return NotificationType.updateEvent;
      case 'delete_event':
      case 'event_delete':
      case 'event_deleted':
      case 'remove_event':
      case 'cancel_event':
      case 'event_cancelled':
      case 'event_canceled':
        return NotificationType.deleteEvent;
      case 'accept_user_registration':
      case 'acceptuserregistration':
        return NotificationType.acceptUserRegistration;
      case 'reject_user_registration':
      case 'rejectuserregistration':
        return NotificationType.rejectUserRegistration;
      default:
        return NotificationType.eventInvitation;
    }
  }

  static NotificationType fromPayload({
    String? type,
    Map<String, dynamic>? data,
    String? title,
    String? body,
  }) {
    final registrationType = registrationNotificationTypeFromFcmData(data);
    if (registrationType != null) return registrationType;

    final rawType =
        type ??
        data?['notification_type']?.toString() ??
        data?['type']?.toString();
    final normalizedType = rawType?.trim().toLowerCase() ?? '';

    const recognizedTypes = {
      'event_invitation',
      'invite_event',
      'event_invite',
      'new_event',
      'create_event',
      'update_event',
      'event_update',
      'event_updated',
      'updated_event',
      'edit_event',
      'delete_event',
      'event_delete',
      'event_deleted',
      'remove_event',
      'cancel_event',
      'event_cancelled',
      'event_canceled',
      'accept_user_registration',
      'reject_user_registration',
    };

    if (rawType != null && rawType.trim().isNotEmpty) {
      if (recognizedTypes.contains(normalizedType)) {
        return fromString(rawType);
      }
    }

    final registrationKey = _resolveRegistrationTypeKey(
      normalizedType,
      data: data,
      title: title,
      body: body,
    );
    if (registrationKey != null) {
      return fromString(registrationKey);
    }

    if (UserRegistrationData.hasFcmPayload(data)) {
      return NotificationType.eventInvitation;
    }

    return inferFromContent(
      data: data,
      title: title,
      body: body,
      fallback: NotificationType.eventInvitation,
    );
  }

  static NotificationType inferFromContent({
    Map<String, dynamic>? data,
    String? title,
    String? body,
    NotificationType fallback = NotificationType.eventInvitation,
  }) {
    final haystack = _normalizedContent(data: data, title: title, body: body);

    if (_containsAny(haystack, const [
      'delete',
      'cancel',
      'remove',
      'event deleted',
      'event cancelled',
      'event canceled',
      'حذف',
      'محذوف',
      'تم حذف',
      'الغاء',
      'إلغاء',
      'الغي',
      'ألغ',
      'تم الغاء',
      'تم إلغاء',
      'ملغي',
      'تم إلغاء الحدث',
      'تم الغاء الحدث',
    ])) {
      return NotificationType.deleteEvent;
    }

    if (_containsAny(haystack, const [
      'update',
      'edit',
      'modified',
      'updated',
      'event updated',
      'تعديل',
      'تم تعديل',
      'تحديث',
      'تم تحديث',
      'جرى تعديل',
      'تم تعديل الحدث',
      'تم تحديث الحدث',
    ])) {
      return NotificationType.updateEvent;
    }

    if (_containsAny(haystack, const [
      'invite',
      'invited',
      'invitation',
      'دعوة',
      'دعوتك',
      'تمت دعوتك',
      'مدعو',
      'دعيت',
    ])) {
      return NotificationType.eventInvitation;
    }

    if (_haystackAcceptRegistration(haystack)) {
      return NotificationType.acceptUserRegistration;
    }
    if (_haystackRejectRegistration(haystack)) {
      return NotificationType.rejectUserRegistration;
    }

    return fallback;
  }

  static String? _resolveRegistrationTypeKey(
    String normalizedType, {
    Map<String, dynamic>? data,
    String? title,
    String? body,
  }) {
    final candidates = <String>[
      normalizedType,
      if (data != null) ...[
        data['notification_type']?.toString() ?? '',
        data['type']?.toString() ?? '',
        data['notificationType']?.toString() ?? '',
        data['event_type']?.toString() ?? '',
        data['action']?.toString() ?? '',
      ],
    ];

    for (final raw in candidates) {
      final key = _normalizeTypeKey(raw);
      if (key == 'accept_user_registration' ||
          key == 'reject_user_registration') {
        return key;
      }
      if (_looksLikeAcceptRegistration(key)) return 'accept_user_registration';
      if (_looksLikeRejectRegistration(key)) return 'reject_user_registration';
    }

    final haystack = _normalizedContent(data: data, title: title, body: body);
    if (_haystackAcceptRegistration(haystack)) {
      return 'accept_user_registration';
    }
    if (_haystackRejectRegistration(haystack)) {
      return 'reject_user_registration';
    }

    return null;
  }

  static String _normalizeTypeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\u0600-\u06FF]'), '');
  }

  static bool _looksLikeAcceptRegistration(String key) {
    if (key.isEmpty) return false;
    return (key.contains('accept') || key.contains('approved')) &&
        (key.contains('user') ||
            key.contains('registration') ||
            key.contains('register'));
  }

  static bool _looksLikeRejectRegistration(String key) {
    if (key.isEmpty) return false;
    return (key.contains('reject') || key.contains('rejected')) &&
        (key.contains('user') ||
            key.contains('registration') ||
            key.contains('register'));
  }

  static bool _haystackAcceptRegistration(String haystack) {
    return haystack.contains('accept_user_registration') ||
        (haystack.contains('موافق') && haystack.contains('تسجيل')) ||
        (haystack.contains('approved') && haystack.contains('registration'));
  }

  static bool _haystackRejectRegistration(String haystack) {
    return haystack.contains('reject_user_registration') ||
        (haystack.contains('رفض') && haystack.contains('تسجيل')) ||
        (haystack.contains('rejected') && haystack.contains('registration'));
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static String _normalizedContent({
    Map<String, dynamic>? data,
    String? title,
    String? body,
  }) {
    final raw = '${title ?? ''} ${body ?? ''} ${jsonEncode(data ?? const {})}'
        .toLowerCase()
        .trim();

    return raw
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }
}

extension NotificationTypeUI on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.eventInvitation:
        return Icons.event_available;
      case NotificationType.updateEvent:
        return Icons.update;
      case NotificationType.deleteEvent:
        return Icons.event_busy;
      case NotificationType.acceptUserRegistration:
        return Icons.verified_user_outlined;
      case NotificationType.rejectUserRegistration:
        return Icons.person_off_outlined;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.eventInvitation:
        return AppColors.primary;
      case NotificationType.updateEvent:
        return AppColors.gold;
      case NotificationType.deleteEvent:
        return AppColors.errorPrimary;
      case NotificationType.acceptUserRegistration:
        return AppColors.secondary;
      case NotificationType.rejectUserRegistration:
        return AppColors.errorPrimary;
    }
  }
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  final int eventId;

  final Map<String, dynamic> data;
  bool isRead;

  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.eventId,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedData = {};
    if (json['data'] != null) {
      if (json['data'] is String) {
        parsedData = Map<String, dynamic>.from(jsonDecode(json['data']));
      } else if (json['data'] is Map) {
        parsedData = Map<String, dynamic>.from(json['data']);
      }
    }

    final int eventId =
        int.tryParse(parsedData['event_id']?.toString() ?? '0') ?? 0;

    final type = NotificationTypeExtension.fromPayload(
      type: json['type']?.toString(),
      data: parsedData,
      title: json['title']?.toString(),
      body: json['body']?.toString(),
    );
    final rawTitle = json['title']?.toString() ?? '';
    final rawBody = json['body']?.toString() ?? '';
    final display = _registrationDisplayIfNeeded(
      type: type,
      data: parsedData,
      title: rawTitle,
      body: rawBody,
    );

    final mergedData = Map<String, dynamic>.from(parsedData);
    final extractedReason =
        UserRegistrationData.extractFromDataRegistrationUser(mergedData) ??
        UserRegistrationData.extractRejectionReason(
          data: mergedData,
          notificationTitle: rawTitle,
          notificationBody: rawBody,
        );
    if (extractedReason != null && extractedReason.isNotEmpty) {
      mergedData['register_description_status'] = extractedReason;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: type,
      title: display?.title ?? rawTitle,
      body: display?.body ?? rawBody,
      eventId: eventId,
      data: mergedData,
      isRead: _readBool(json['is_read']),
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  static RegistrationNotificationContent? _registrationDisplayIfNeeded({
    required NotificationType type,
    required Map<String, dynamic> data,
    required String title,
    required String body,
  }) {
    final registrationType =
        registrationNotificationTypeFromFcmData(data) ?? type;
    if (!registrationType.isRegistrationApproval) return null;

    return RegistrationNotificationDisplay.resolve(
      type: registrationType,
      data: data,
      title: title,
      body: body,
    );
  }

  NotificationModel copyWith({bool? isRead, String? title, String? body}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      eventId: eventId,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  NotificationType get resolvedType =>
      NotificationTypeExtension.inferFromContent(
        data: data,
        title: title,
        body: body,
        fallback: type,
      );

  String get displayTitle {
    if (!resolvedType.isRegistrationApproval) return title;
    return RegistrationNotificationDisplay.resolve(
      type: resolvedType,
      data: data,
      title: title,
      body: body,
    ).title;
  }

  String get displayBody {
    if (!resolvedType.isRegistrationApproval) return body;
    return RegistrationNotificationDisplay.resolve(
      type: resolvedType,
      data: data,
      title: title,
      body: body,
    ).body;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true';
  }
}

class NotificationsResponse {
  final List<NotificationModel> items;
  final int currentPage;
  final String? urlNextPage;
  final String? urlPrePage;
  final String? urlFirstPage;
  final String? urlLastPage;
  final int totalPages;
  final int totalItems;
  final bool hasMorePages;

  NotificationsResponse({
    required this.items,
    required this.currentPage,
    this.urlNextPage,
    this.urlPrePage,
    this.urlFirstPage,
    this.urlLastPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasMorePages,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'] ?? {};
    final itemsJson = notifications['items'] as List? ?? [];

    return NotificationsResponse(
      items: itemsJson.map((e) => NotificationModel.fromJson(e)).toList(),
      currentPage: notifications['current_page'] ?? 1,
      urlNextPage: notifications['url_next_page'],
      urlPrePage: notifications['url_pre_page'],
      urlFirstPage: notifications['url_first_page'],
      urlLastPage: notifications['url_last_page'],
      totalPages: notifications['total_pages'] ?? 1,
      totalItems: notifications['total_items'] ?? itemsJson.length,
      hasMorePages: notifications['has_more_pages'] ?? false,
    );
  }
}
