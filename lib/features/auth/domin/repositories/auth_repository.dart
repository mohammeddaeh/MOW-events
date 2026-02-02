import 'dart:io';

import 'package:mow_events/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<void> sendResetCode(String email);
  Future<void> verifyResetCode(String email, String code);
  Future<void> resetPassword(String email, String code, String newPassword);
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? address,
    File? image,
  });
  Future<UserModel> getProfile();
}
