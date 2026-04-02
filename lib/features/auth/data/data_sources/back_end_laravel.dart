import 'dart:io';

import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/helpers/http_helper.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';

class BackEndLaravel {
  Future<Json> login(String email, String password) async {
    return await HttpHelper.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    }, withAuth: false);
  }

  Future<Json> logout() async {
    return await HttpHelper.delete(ApiEndpoints.logout, withAuth: true);
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
    return await HttpHelper.postMultipart(ApiEndpoints.changePassword, {
      'old_password': oldPassword,
      'new_password': newPassword,
    }, null, withAuth: true);
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
    final res = await HttpHelper.get(ApiEndpoints.profile, withAuth: true);

    if (res['status'] != true) {
      throw ApiException(res['message'] ?? "Unable to fetch profile");
    }

    final userJson = res['data']['user'];
    return UserModel.fromJson(userJson);
  }
}
