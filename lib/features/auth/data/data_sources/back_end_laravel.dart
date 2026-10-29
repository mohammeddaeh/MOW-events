import 'dart:io';

import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/helpers/http_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';

class BackEndLaravel {
  Future<List<Department>> fetchDepartmentsForRegistration() async {
    final res = await HttpHelper.get(
      ApiEndpoints.showRegisterDepartmentsAll,
      withAuth: false,
      suppressErrorSnackBar: true,
    );

    if (res['status'] != true) {
      throw ApiException(_responseMessage(res));
    }

    final data = res['data'];
    final rawItems = _extractDepartmentItems(data);
    return rawItems
        .whereType<Map>()
        .map((e) => Department.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id > 0 && d.name.trim().isNotEmpty)
        .toList();
  }

  String _responseMessage(Json res) {
    return ApiMessageLocalizer.extractFromResponse(
      res,
      fallback: AppTexts.failedToLoadDepartments,
    );
  }

  List<dynamic> _extractDepartmentItems(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];

    final departments = data['departments'];
    if (departments is Map) {
      final items = departments['items'];
      if (items is List) return items;
    }
    if (departments is List) return departments;

    if (data['items'] is List) return data['items'] as List;
    if (data['result'] is List) return data['result'] as List;

    return const [];
  }

  Future<Json> register(Map<String, String> fields) async {
    return await HttpHelper.postMultipart(
      ApiEndpoints.register,
      fields,
      null,
      withAuth: false,
      suppressErrorSnackBar: true,
    );
  }

  /// إعادة تقديم الطلب بعد الرفض (يتطلب توكن المستخدم).
  Future<Json> editRegister(Map<String, String> fields) async {
    return await HttpHelper.postMultipart(
      ApiEndpoints.editRegister,
      fields,
      null,
      withAuth: true,
      suppressErrorSnackBar: true,
    );
  }

  Future<Json> login({
    required String identifier,
    required String password,
  }) async {
    return await HttpHelper.postMultipart(
      ApiEndpoints.login,
      {'email': identifier.trim(), 'password': password},
      null,
      withAuth: false,
      suppressErrorSnackBar: true,
    );
  }

  /// [deviceToken]: توكن FCM للجهاز حتى يفصله الباك عن هذا الحساب.
  Future<Json> logout({String? deviceToken}) async {
    final endpoint = deviceToken == null || deviceToken.isEmpty
        ? ApiEndpoints.logout
        : '${ApiEndpoints.logout}?device_token=${Uri.encodeQueryComponent(deviceToken)}';
    return await HttpHelper.delete(endpoint, withAuth: true);
  }

  Future<Json> sendResetCode(String email) async {
    return await HttpHelper.post(ApiEndpoints.forgotPassword, {
      'email': email,
    }, withAuth: false);
  }

  Future<Json> verifyResetCode(String email, String code) async {
    return await HttpHelper.post(ApiEndpoints.checkResetCode, {
      'email': email,
      'code': code,
    }, withAuth: false);
  }

  Future<Json> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    return await HttpHelper.post(ApiEndpoints.resetPassword, {
      'email': email,
      'code': code,
      'password': newPassword,
    }, withAuth: false);
  }

  Future<Json> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await HttpHelper.postMultipart(
      ApiEndpoints.changePassword,
      {'old_password': oldPassword, 'new_password': newPassword},
      null,
      withAuth: true,
    );
  }

  Future<Json> editProfile(
    Map<String, dynamic> updatedData, {
    File? image,
  }) async {
    if (image != null) {
      return await HttpHelper.postMultipart(
        ApiEndpoints.editProfile,
        updatedData.map((key, value) => MapEntry(key, value.toString())),
        image,
        withAuth: true,
      );
    }
    return await HttpHelper.post(
      ApiEndpoints.editProfile,
      updatedData,
      withAuth: true,
    );
  }

  Future<UserModel> getProfile() async {
    final res = await HttpHelper.get(
      ApiEndpoints.profile,
      withAuth: true,
      suppressErrorSnackBar: true,
    );

    if (res['status'] != true) {
      throw ApiException(
        ApiMessageLocalizer.extractFromResponse(
          res,
          fallback: AppTexts.unableToFetchProfile,
        ),
      );
    }

    final userJson = res['data']['user'];
    return UserModel.fromJson(userJson);
  }
}
