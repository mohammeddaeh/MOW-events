import 'dart:convert';

import 'package:flutter/material.dart';

enum NotificationType { eventInvitation, updateEvent, deleteEvent }

extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.eventInvitation:
        return 'event_invitation';
      case NotificationType.updateEvent:
        return 'update_event';
      case NotificationType.deleteEvent:
        return 'delete_event';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'event_invitation':
        return NotificationType.eventInvitation;
      case 'update_event':
        return NotificationType.updateEvent;
      case 'delete_event':
        return NotificationType.deleteEvent;
      default:
        return NotificationType.eventInvitation;
    }
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
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.eventInvitation:
        return Colors.green;
      case NotificationType.updateEvent:
        return Colors.orange;
      case NotificationType.deleteEvent:
        return Colors.red;
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

    print('Notification ID: ${json['id']}');
    print('Raw JSON data: ${json['data']}');
    print('Parsed data: $parsedData');

    final int eventId =
        int.tryParse(parsedData['event_id']?.toString() ?? '0') ?? 0;

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: NotificationTypeExtension.fromString(json['type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      eventId: eventId,
      data: parsedData,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      eventId: eventId,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
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
