import 'dart:async';

import 'package:mow_events/core/utils/error/network_exceptions.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/event/data/data_sources/events_backend.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/event_entity.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';

class EventRepositoryImpl implements EventsRepository {
  final EventsBackend backend;

  EventRepositoryImpl({required this.backend});

  Future<T> _safe<T>(
    Future<T> future, {
    required String timeoutMsg,
    Duration duration = const Duration(seconds: 15),
  }) {
    return future.timeout(
      duration,
      onTimeout: () => throw TimeoutException(timeoutMsg),
    );
  }

  Future<T> withNetworkCheck<T>(Future<T> Function() action) async {
    final isOnline = await NetworkManager.instance.isConnected();
    if (!isOnline) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.noInternetConnection,
        message: AppTexts.checkYourInternetConnectionBeforeProceeding,
      );
      throw NoInternetException(AppTexts.noInternetConnection);
    }
    return action();
  }

  @override
  Future<List<EventEntity>> getEvents({required int page}) => _safe(
    backend.getEvents(page: page),
    timeoutMsg: 'Fetching events timed out',
  );

  @override
  Future<EventModel> createEvent(EventEntity event) {
    if (event is! EventModel) throw ArgumentError('Event must be EventModel');

    return withNetworkCheck(
      () => _safe(
        backend.createEvent(event),
        timeoutMsg: 'Creating event timed out',
      ),
    );
  }

  @override
  Future<EventModel> getEventDetails(int id) {
    if (id <= 0) throw ArgumentError('Invalid event ID');
    return _safe(
      backend.getEventDetails(id),
      timeoutMsg: 'Fetching event details timed out',
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<EventModel> updateEvent({
    required int id,
    required EventEntity event,
  }) {
    if (id <= 0) throw ArgumentError('Invalid event ID');
    if (event is! EventModel) throw ArgumentError('Event must be EventModel');
    return _safe(
      backend.updateEvent(id: id, event: event),
      timeoutMsg: 'Updating event timed out',
    );
  }

  @override
  Future<bool> deleteEvents(List<int> ids) {
    if (ids.isEmpty) throw ArgumentError('No IDs provided');
    return _safe(
      backend.deleteEvents(ids),
      timeoutMsg: 'Deleting events timed out',
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<List<int>> getEventMembers(int id) {
    if (id <= 0) throw ArgumentError('Invalid event ID');
    return _safe(
      backend.getMembersInEvent(id),
      timeoutMsg: 'Fetching event members timed out',
    );
  }

  @override
  Future<List<UserEntity>> getAllUsers({int? departmentId}) {
    return _safe(
      backend
          .getAllUsers(departmentId: departmentId)
          .then((list) => list.map((m) => m.toEntity()).toList()),
      timeoutMsg: 'Fetching users timed out',
    );
  }

  @override
  Future<EventModel> getEvent(int id) {
    if (id <= 0) throw ArgumentError('Invalid event ID');
    return _safe(
      backend.getEventDetails(id),
      timeoutMsg: 'Fetching event by ID timed out',
      duration: const Duration(seconds: 10),
    );
  }
}
