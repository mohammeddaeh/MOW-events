import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';

class AuthStorage {
  final _storage = Get.find<AppLocalStorage>();

  Future<void> saveToken(String token) =>
      _storage.write(StorageKeys.token, token);

  String? get token => _storage.read(StorageKeys.token);

  Future<void> saveUser(Map json) => _storage.write(StorageKeys.user, json);

  Map? get user => _storage.read(StorageKeys.user);

  Future<void> clear() async {
    await _storage.remove(StorageKeys.token);
    await _storage.remove(StorageKeys.user);
  }
}
