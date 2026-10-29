import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/error/app_exciption.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/orders/data/orders_backend.dart';

class OrdersController extends GetxController with WidgetsBindingObserver {
  final OrdersBackend _backend;

  OrdersController({OrdersBackend? backend})
    : _backend = backend ?? OrdersBackend();

  final RxList<UserModel> _allOrders = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> processingOrderIds = <int>{}.obs;

  bool get isOffline => !NetworkManager.instance.isOnline.value;

  /// طلبات بانتظار المراجعة فقط — الوحيدة القابلة للقبول/الرفض.
  List<UserModel> get pendingOrders =>
      _allOrders.where((o) => o.registrationData.isPending).toList();

  /// طلبات مرفوضة سابقاً (يحتفظ بها الباك لغرض السجل) — للعرض فقط، بلا إجراءات.
  List<UserModel> get rejectedOrders =>
      _allOrders.where((o) => o.registrationData.isRejected).toList();

  /// فحص دوري لطلبات الانضمام حتى يظهر البادج حتى لو لم يصل الإشعار.
  static const Duration _pollInterval = Duration(minutes: 2);
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchOrders();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => fetchOrders(silent: true),
    );
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchOrders(silent: true);
    }
  }

  /// [silent]: تحديث بالخلفية بلا مؤشر تحميل ولا رسائل خطأ.
  Future<void> fetchOrders({bool silent = false}) async {
    if (!InternetGuard.ensureOnline(showMessage: false)) {
      return;
    }
    if (silent && isLoading.value) return;

    if (!silent) isLoading.value = true;
    try {
      final result = await _backend.fetchOrders();
      _allOrders.value = result;
    } catch (e) {
      if (!silent) {
        AppSnackBars.errorSnackBar(
          title: AppTexts.warningTitle,
          message: _errorMessage(e),
        );
      }
    } finally {
      if (!silent) isLoading.value = false;
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

    final order = _allOrders.firstWhereOrNull((o) => o.id == orderId);
    if (order == null || !order.registrationData.isPending) {
      // تم البت بهذا الطلب مسبقاً (على الأرجح استجابة قديمة من القائمة) — تجاهل الإجراء المكرر.
      return false;
    }

    processingOrderIds.add(orderId);
    try {
      await _backend.changeOrderStatus(
        orderId: orderId,
        status: status,
        description: description,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.warningTitle,
        message: _errorMessage(e),
      );
      return false;
    } finally {
      processingOrderIds.remove(orderId);
    }
  }

  String _errorMessage(Object error) {
    if (error is AppException) {
      return ApiMessageLocalizer.forSnackBar(error.message);
    }
    return AppTexts.orderActionFailed;
  }
}
