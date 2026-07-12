import 'package:get/get.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/orders/data/orders_backend.dart';

class OrdersController extends GetxController {
  final OrdersBackend _backend;

  OrdersController({OrdersBackend? backend})
    : _backend = backend ?? OrdersBackend();

  final RxList<UserModel> orders = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> processingOrderIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!InternetGuard.ensureOnline(showMessage: false)) {
      // ignore: avoid_print
      print('[OrdersController] offline, skipping fetchOrders');
      return;
    }

    isLoading.value = true;
    try {
      final result = await _backend.fetchOrders();
      orders.value = result;
      // ignore: avoid_print
      print('[OrdersController] fetched ${result.length} orders');
    } catch (e) {
      // ignore: avoid_print
      print('[OrdersController] fetchOrders failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    return _changeStatus(orderId: orderId, status: 'accept');
  }

  Future<bool> rejectOrder(int orderId, {required String description}) async {
    return _changeStatus(
      orderId: orderId,
      status: 'reject',
      description: description,
    );
  }

  Future<bool> _changeStatus({
    required int orderId,
    required String status,
    String? description,
  }) async {
    if (!InternetGuard.ensureOnline()) return false;
    if (processingOrderIds.contains(orderId)) return false;

    processingOrderIds.add(orderId);
    try {
      await _backend.changeOrderStatus(
        orderId: orderId,
        status: status,
        description: description,
      );
      orders.removeWhere((o) => o.id == orderId);
      return true;
    } catch (_) {
      return false;
    } finally {
      processingOrderIds.remove(orderId);
    }
  }
}
