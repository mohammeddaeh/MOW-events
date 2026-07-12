import 'package:get/get.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/category/data/data_sources/category_backend.dart';
import 'package:mow_events/features/category/data/repsitories_impl/categories_repository_impl.dart';
import 'package:mow_events/features/category/domin/repositories/categories_repository.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/data/data_sources/events_backend.dart';
import 'package:mow_events/features/event/data/repsitories_impl/event_repository_impl.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';
import 'package:mow_events/features/event/presentation/controller/day_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/monthly_controller.dart';
import 'package:mow_events/features/event/presentation/controller/week_controller.dart';
import 'package:mow_events/features/event/presentation/controller/year_controller.dart';
import 'package:mow_events/features/notifications/data/data_sources/notifications_backend.dart';
import 'package:mow_events/features/notifications/data/repsitories_impl/notifications_repository_impl.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';
import 'package:mow_events/features/orders/presentation/orders_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final currentUser = AuthService.currentUser!;

    Get.put<EventsBackend>(EventsBackend());
    Get.put<EventsRepository>(EventRepositoryImpl(backend: Get.find()));
    Get.put<HomeController>(HomeController(eventRepo: Get.find()));

    Get.put<CategoriesBackend>(CategoriesBackend());
    Get.put<CategoriesRepository>(
      CategoriesRepositoryImpl(backend: Get.find()),
    );
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      Get.put<CategoriesController>(
        CategoriesController(repository: Get.find()),
      );
      Get.put<OrdersController>(OrdersController());
    }
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put<NotificationsController>(
        NotificationsController(
          repository: NotificationsRepositoryImpl(
            backend: NotificationsBackend(),
          ),
        ),
        permanent: true,
      );
    }

    Get.lazyPut<DayController>(() => DayController());
    Get.lazyPut<WeekController>(() => WeekController());
    Get.lazyPut<MonthlyController>(() => MonthlyController());
    Get.lazyPut<YearController>(() => YearController());
  }
}
