import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/event_entity.dart';

abstract class EventsRepository {
  Future<List<EventEntity>> getEvents({required int page});
  Future<EventModel> createEvent(EventEntity event);
  Future<EventModel> getEventDetails(int id);
  Future<EventModel> updateEvent({required int id, required EventEntity event});
  Future<bool> deleteEvents(List<int> ids);
  Future<List<int>> getEventMembers(int id);
  Future<List<EventMemberDisplay>> getEventMembersWithDetails(int id);
  Future<List<UserEntity>> getAllUsers({int? departmentId});
  Future<EventModel> getEvent(int id);
}
