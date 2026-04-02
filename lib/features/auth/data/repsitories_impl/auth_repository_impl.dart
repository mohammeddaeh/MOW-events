import 'dart:async';
import 'dart:io';
import 'package:mow_events/core/utils/http/api_exceptions.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/data_sources/back_end_laravel.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BackEndLaravel backend;

  AuthRepositoryImpl({required this.backend});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await backend.login(email, password);
    final data = response['data'];
    final token = data['access_token'];
    final userJson = data['user'];

    await AuthService.setToken(token);
    await AuthService.saveUser(userJson);

    return UserModel.fromJson(userJson);
  }

  @override
  Future<void> logout() async {
    try {
      await backend.logout();
    } catch (_) {}
  }

  @override
  Future<void> sendResetCode(String email) async {
    final res = await backend.sendResetCode(email);
    if (res['status'] != true) {
      throw ApiException(res['message'] ?? AppTexts.codeCouldNotBeSent);
    }
  }

  @override
  Future<void> verifyResetCode(String email, String code) async {
    final res = await backend.verifyResetCode(email, code);
    if (res['status'] != true) {
      throw ApiException(res['message'] ?? AppTexts.theCodeIsIncorrect);
    }
  }

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final res = await backend.resetPassword(email, code, newPassword);
    if (res['status'] != true) {
      throw ApiException(
        res['message'] ?? AppTexts.thePasswordHasNotBeenChanged,
      );
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await backend.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    if (res['status'] != true) {
      throw ApiException(
        res['message'] ?? AppTexts.thePasswordHasNotBeenChanged,
      );
    }
  }

  @override
  Future<UserModel> getProfile() async {
    return await backend.getProfile();
  }

  @override
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? address,
    File? image,
    bool removeImage = false,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');

    final dataToSend = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': normalizedPhone,
      'address': address,
    };
    if (removeImage) {
      dataToSend['image'] = null;
    }

    final res = await backend.editProfile(dataToSend, image: image);

    if (res['status'] != true) {
      throw ApiException(res['message'] ?? AppTexts.unableToUpdateProfile);
    }

    final userJson = res['data']['user'];
    return UserModel.fromJson(userJson);
  }
}
