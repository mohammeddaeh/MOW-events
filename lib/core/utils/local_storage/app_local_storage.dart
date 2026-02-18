import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppLocalStorage extends GetxService {
  final GetStorage _storage = GetStorage();

  T? read<T>(String key) => _storage.read<T>(key);

  Future<void> write(String key, dynamic value) async {
    await _storage.write(key, value);
  }

  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  Future<void> clearAll() async {
    await _storage.erase();
  }
}
