import 'package:get/get.dart';
import 'package:mow_events/core/alarm/event_alarm_service.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/features/auth/data/data_sources/back_end_laravel.dart';
import 'package:mow_events/features/auth/data/repsitories_impl/auth_repository_impl.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager(), permanent: true);
    Get.put(AppLocalStorage(), permanent: true);

    Get.lazyPut<BackEndLaravel>(() => BackEndLaravel());
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(backend: Get.find()));

    Get.put<AuthController>(
      AuthController(authRepo: Get.find()),
      permanent: true,
    );
    Get.put<UserAccessController>(
      UserAccessController(authRepo: Get.find()),
      permanent: true,
    );

    if (!Get.isRegistered<EventAlarmService>()) {
      Get.put<EventAlarmService>(EventAlarmService(), permanent: true);
    }
  }
}
