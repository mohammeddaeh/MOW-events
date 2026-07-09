import 'dart:io';

import 'package:mow_events/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  });

  /// تعديل طلب التسجيل بعد الرفض (نفس حقول التسجيل + توكن).
  Future<UserModel> updateRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  });
  Future<UserModel> login({
    required String identifier,
    required String password,
  });
  Future<void> logout();
  Future<void> sendResetCode(String email);
  Future<void> verifyResetCode(String email, String code);
  Future<void> resetPassword(String email, String code, String newPassword);
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? address,
    File? image,
    bool removeImage = false,
  });
  Future<UserModel> getProfile();
}
