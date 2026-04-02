import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

import '../../../../core/utils/helpers/http_helper.dart';

class EventsBackend {
  Future<List<UserListItem>> getAllUsers({int? departmentId}) async {
    final queryParams = <String>[
      'countItems=all',
      'keys[0]=id',
      'keys[1]=first_name',
      'keys[2]=last_name',
      'keys[3]=department',
    ];

    if (departmentId != null) {
      queryParams.add('filter[department_id][0]=$departmentId');
    }

    final url = '${ApiEndpoints.alluser}?${queryParams.join('&')}';

    final res = await HttpHelper.get(url);

    final List<dynamic> items = res['data']?['users'] as List<dynamic>? ?? [];

    return items.map((e) => UserListItem.fromJson(e)).toList();
  }

  Future<List<EventModel>> getEvents({int page = 1}) async {
    final url = '${ApiEndpoints.eventsIndex}?page=$page';

    final res = await HttpHelper.get(url);

    final eventsData = res['data']?['events']?['items'] as List<dynamic>? ?? [];
    return eventsData.map((e) => EventModel.fromJson(e)).toList();
  }

  Future<EventModel> createEvent(EventModel event) async {
    EventValidator.validate(event);

    final formData = event.toForm();

    final res = await HttpHelper.postMultipart(
      ApiEndpoints.eventsStore,
      formData,
      null,
    );
    final eventJson = res['data']['event'] as Map<String, dynamic>;
    return EventModel.fromJson(eventJson);
  }

  Future<EventModel> updateEvent({
    required int id,
    required EventModel event,
  }) async {
    if (id <= 0) throw ArgumentError('Invalid event ID');

    EventValidator.validate(event);

    final formData = event.toForm();
    final url = ApiEndpoints.eventsUpdate(id);
    final res = await HttpHelper.postMultipart(url, formData, null);

    return EventModel.fromJson(res['data']['event']);
  }

  Future<bool> deleteEvents(List<int> ids) async {
    if (ids.isEmpty) throw ArgumentError('No IDs provided');

    final query = ids
        .asMap()
        .entries
        .map((e) => 'ids[${e.key}]=${e.value}')
        .join('&');
    final url = '${ApiEndpoints.eventsDelete}?$query';

    await HttpHelper.delete(url);
    return true;
  }

  Future<List<int>> getMembersInEvent(int id) async {
    if (id <= 0) throw ArgumentError('Invalid event ID');
    final url = ApiEndpoints.eventShowMembers(id);
    final res = await HttpHelper.get(url);
    final data = res['data'];
    if (data == null) return [];

    final raw =
        data['members'] ?? data['users'] ?? (data is List ? data : null);
    if (raw == null || raw is! List) return [];

    return raw
        .map((e) {
          if (e is num) return e.toInt();
          if (e is Map && e['id'] != null) {
            final v = e['id'];
            return (v is num ? v : int.tryParse(v.toString()));
          }
          return int.tryParse(e.toString());
        })
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
  }

  /// جلب المشاركين مع التفاصيل (اسم، صورة، قسم) إن وُجدت في الاستجابة
  Future<List<EventMemberDisplay>> getEventMembersWithDetails(int id) async {
    if (id <= 0) return [];
    final url = ApiEndpoints.eventShowMembers(id);
    final res = await HttpHelper.get(url);
    final data = res['data'];
    if (data == null) return [];

    final raw =
        data['members'] ?? data['users'] ?? (data is List ? data : null);
    if (raw == null || raw is! List) return [];

    final list = <EventMemberDisplay>[];
    for (final e in raw) {
      if (e is Map && e['id'] != null) {
        list.add(EventMemberDisplay.fromJson(Map<String, dynamic>.from(e)));
      } else if (e is num) {
        list.add(
          EventMemberDisplay(
            id: e.toInt(),
            firstName: 'User',
            lastName: '${e.toInt()}',
          ),
        );
      } else {
        final id = int.tryParse(e.toString());
        if (id != null && id > 0) {
          list.add(
            EventMemberDisplay(id: id, firstName: 'User', lastName: '$id'),
          );
        }
      }
    }
    return list;
  }

  Future<EventModel> getEventDetails(int id) async {
    if (id <= 0) throw ArgumentError('Invalid event ID');

    final url = ApiEndpoints.eventsShow(id);

    final res = await HttpHelper.get(url);

    return EventModel.fromJson(
      (res['data']?['result'] ?? res['data']) as Map<String, dynamic>,
    );
  }
}
