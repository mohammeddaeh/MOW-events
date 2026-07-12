import 'package:mow_events/core/app_update/data/models/app_settings_model.dart';
import 'package:mow_events/core/utils/helpers/http_helper.dart';
import 'package:mow_events/core/utils/http/api_endpoints.dart';

class AppSettingsBackend {
  Future<AppSettingsModel> showSettings() async {
    final res = await HttpHelper.get(
      ApiEndpoints.showSettings,
      withAuth: false,
      suppressErrorSnackBar: true,
    );
    return AppSettingsModel.fromJson(res['data']['settings']);
  }
}
