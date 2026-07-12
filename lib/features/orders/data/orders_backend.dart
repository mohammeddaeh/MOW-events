import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/helpers/http_helper.dart';
import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';

class OrdersBackend {
  Future<List<UserModel>> fetchOrders() async {
    final res = await HttpHelper.get(
      ApiEndpoints.usersOrders,
      suppressErrorSnackBar: true,
    );

    final items = (res['data']?['orders'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> changeOrderStatus({
    required int orderId,
    required String status,
    String? description,
  }) async {
    assert(status == 'accept' || status == 'reject');

    final res = await HttpHelper.get(
      ApiEndpoints.changeOrderStatus(
        orderId: orderId,
        status: status,
        description: description,
      ),
      suppressErrorSnackBar: true,
    );

    if (res['status'] != true) {
      throw ApiException(
        ApiMessageLocalizer.extractFromResponse(
          res,
          fallback: AppTexts.anUnknownEerrorHasOccurred,
        ),
      );
    }
  }
}
