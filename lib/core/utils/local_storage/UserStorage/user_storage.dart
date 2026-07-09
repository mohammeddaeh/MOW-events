import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

class UserStorage {
  final _storage = Get.find<AppLocalStorage>();

  int? get uid => AuthService.currentUser?.id;

  int? _resolveUserId([int? userId]) => userId ?? uid;

  List<String> _userScopedKeys(int userId) => [
    StorageKeys.categories(userId),
    StorageKeys.events(userId),
    StorageKeys.reminders(userId),
    StorageKeys.home(userId),
    StorageKeys.scheduledReminders(userId),
    StorageKeys.ignoredDefaults(userId),
    StorageKeys.defaultReminders(userId),
  ];

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
    final id = _resolveUserId();
    if (id == null) return;
    await clearAllUserDataFor(id);
  }

  Future<void> clearAllUserDataFor(int userId) async {
    for (final key in _userScopedKeys(userId)) {
      await _storage.remove(key);
    }

    // Cleanup for older builds where default reminders were stored globally.
    await _storage.remove(StorageKeys.legacyDefaultReminders);
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

  Future<void> saveDefaultReminders(List<Map<String, dynamic>> data) async {
    final id = uid;
    if (id == null) return;
    await _storage.write(StorageKeys.defaultReminders(id), data);
  }

  List<dynamic>? get defaultReminders {
    final id = uid;
    if (id == null) return null;
    return _storage.read(StorageKeys.defaultReminders(id));
  }
}
