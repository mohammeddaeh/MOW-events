import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

class UserStorage {
  final _storage = Get.find<AppLocalStorage>();

  int? get uid => AuthService.currentUser?.id;

  Future<void> saveCategories(List data) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.categories(id), data);
  }

  List? get categories {
    final id = uid;
    if (id == null) return null;
    return _storage.read(StorageKeys.categories(id));
  }

  Future<void> saveEvents(List data) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.events(id), data);
  }

  List? get events {
    final id = uid;
    if (id == null) return null;
    return _storage.read(StorageKeys.events(id));
  }

  Future<void> saveHome(Map data) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.home(id), data);
  }

  Map? get home {
    final id = uid;
    if (id == null) return null;
    return _storage.read(StorageKeys.home(id));
  }

  Future<void> clearAllUserData() async {
    final id = uid;
    if (id == null) return;
    await _storage.remove(StorageKeys.categories(id));
    await _storage.remove(StorageKeys.events(id));
    await _storage.remove(StorageKeys.reminders(id));
    await _storage.remove(StorageKeys.home(id));
    await _storage.clearAll();
  }

  Future<void> saveScheduledReminders(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.scheduledReminders(id), data);
  }

  Map<String, dynamic>? get scheduledReminders {
    final id = uid;
    if (id == null) return null;
    return _storage.read(StorageKeys.scheduledReminders(id));
  }

  Future<void> saveIgnoredDefaultReminders(
    Map<String, List<String>> data,
  ) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.ignoredDefaults(id), data);
  }

  Map<String, List<String>>? get ignoredDefaultReminders {
    final id = uid;
    if (id == null) return null;
    return (_storage.read(StorageKeys.ignoredDefaults(id)) as Map?)?.map(
      (k, v) => MapEntry(k.toString(), (v as List).cast<String>()),
    );
  }
}
