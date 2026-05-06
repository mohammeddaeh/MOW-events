import 'package:get/get.dart';
import 'package:mow_events/features/alarm/presentation/controllers/alarm_ringing_controller.dart';

class AlarmRingingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AlarmRingingController(), permanent: false);
  }
}
