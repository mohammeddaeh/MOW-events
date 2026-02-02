import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
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
    // print('[EventsBackend] GET: $url');

    final res = await HttpHelper.get(url);
    // print('[EventsBackend] Response: $res');

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

    final members = res['data']?['members'] as List<dynamic>? ?? [];
    return members.map((e) => (e as num).toInt()).toList();
  }

  // Future<List<CategoryModel>> getCategories() async {
  //   final url = ApiEndpoints.showCategories;

  //   final res = await HttpHelper.get(url);

  //   final items = res['data']?['categories']?['items'] as List<dynamic>? ?? [];
  //   return items.map((e) => CategoryModel.fromJson(e)).toList();
  // }

  Future<EventModel> getEventDetails(int id) async {
    if (id <= 0) throw ArgumentError('Invalid event ID');

    final url = ApiEndpoints.eventsShow(id);

    final res = await HttpHelper.get(url);

    return EventModel.fromJson(res['data']['result']);
  }
}
