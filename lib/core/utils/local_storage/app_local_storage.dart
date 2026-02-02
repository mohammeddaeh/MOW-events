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

// class AppLocalStorage extends GetxController {
//   static final AppLocalStorage instance = AppLocalStorage._internal();
//   // static const offlineQueueKey = 'offline_event_queue';

//   factory AppLocalStorage() => instance;

//   AppLocalStorage._internal();

//   final _storage = GetStorage();

//   /// Generic method to save data
//   Future<void> saveData<T>(String key, T value) async {
//     await _storage.write(key, value);
//   }

//   /// Generic method to read data
//   T? readData<T>(String key) {
//     return _storage.read<T>(key);
//   }

//   /// Generic method to remove data
//   Future<void> removeData(String key) async {
//     await _storage.remove(key);
//   }

//   /// Clear all data in storage
//   Future<void> clearAll() async {
//     await _storage.erase();
//   }
// }
