import 'dart:io';

import 'package:mow_events/core/utils/error/api_exceptions.dart'
    show ApiException;
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/data_sources/back_end_laravel.dart';
import 'package:mow_events/features/auth/data/models/register_conflict_type.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/utils/auth_api_fields.dart';
import 'package:mow_events/features/auth/utils/auth_response_parser.dart';
import 'package:mow_events/features/auth/utils/register_conflict_parser.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BackEndLaravel backend;

  AuthRepositoryImpl({required this.backend});

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  }) async {
    final res = await backend.register(
      AuthApiFields.registration(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        departmentId: departmentId,
        isManager: isManager,
      ),
    );

    if (res['status'] != true) {
      final conflict = RegisterConflictParser.fromRegisterResponse(res);
      if (conflict != null) {
        throw ApiException(_registerConflictMessage(conflict));
      }
      throw ApiException(
        ApiMessageLocalizer.localize(
          res['message']?.toString() ?? AppTexts.unableToCreateAccount,
        ),
      );
    }

    final session = AuthResponseParser.parseSession(res);
    final registeredUser = UserModel.fromJson(session.userJson);
    await AuthService.setToken(session.token);
    await AuthService.saveUser(registeredUser.toJson());

    return registeredUser;
  }

  @override
  Future<UserModel> updateRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  }) async {
    final res = await backend.editRegister(
      AuthApiFields.registration(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        departmentId: departmentId,
        isManager: isManager,
      ),
    );

    if (res['status'] != true) {
      final conflict = RegisterConflictParser.fromRegisterResponse(res);
      if (conflict != null) {
        throw ApiException(_registerConflictMessage(conflict));
      }
      throw ApiException(
        ApiMessageLocalizer.localize(
          res['message']?.toString() ?? AppTexts.unableToCreateAccount,
        ),
      );
    }

    final session = AuthResponseParser.parseSession(
      res,
      fallbackToken: AuthService.token,
    );
    final updatedUser = UserModel.fromJson(session.userJson);
    await AuthService.setToken(session.token);
    await AuthService.saveUser(updatedUser.toJson());

    return updatedUser;
  }

  static String _registerConflictMessage(RegisterConflictType type) {
    switch (type) {
      case RegisterConflictType.emailPendingReview:
        return AppTexts.emailPendingAdminReview;
      case RegisterConflictType.phoneTaken:
        return AppTexts.phoneAlreadyTaken;
      case RegisterConflictType.emailTaken:
        return AppTexts.emailAlreadyTaken;
    }
  }

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await backend.login(
      identifier: identifier,
      password: password,
    );

    if (response['status'] != true) {
      throw ApiException(
        ApiMessageLocalizer.extractFromResponse(
          response,
          fallback: AppTexts.incorrectEmailOrPassword,
        ),
      );
    }

    final session = AuthResponseParser.parseSession(response);
    final loggedInUser = UserModel.fromJson(session.userJson);

    await AuthService.setToken(session.token);
    await AuthService.saveUser(loggedInUser.toJson());

    return loggedInUser;
  }

  @override
  Future<void> logout({String? deviceToken}) async {
    try {
      await backend.logout(deviceToken: deviceToken);
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
