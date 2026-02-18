import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_image_preview_dialog.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepo;
  final AuthController authController = Get.find<AuthController>();

  RxBool isLoading = false.obs;
  RxBool isImageLoading = false.obs;
  Rx<UserModel?> user = Rx<UserModel?>(null);

  final ImagePicker _picker = ImagePicker();

  ProfileController({required AuthRepository authRepo}) : _authRepo = authRepo;

  @override
  void onInit() {
    super.onInit();
    _loadFromLocal();
    fetchProfileIfOnline();
  }

  void _loadFromLocal() {
    final cached = AuthService.currentUser;
    if (cached != null) {
      user.value = cached;
    }
  }

  Future<void> fetchProfileIfOnline() async {
    if (!NetworkManager.instance.isOnline.value) return;
    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final updatedUser = await _authRepo.getProfile();

      _updateUser(updatedUser);
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: AppTexts.unableToFetchProfile,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) await updateProfileImage(File(picked.path));
  }

  Future<void> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final file = File(picked.path);
      final accepted = await showImagePreviewDialog(
        context: Get.context!,
        image: file,
      );
      if (accepted) {
        await updateProfileImage(file);
      }
    }
  }

  Future<bool> showImagePreviewDialog({
    required BuildContext context,
    required File image,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => AppImagePreviewDialog(
            image: image,
            onConfirm: () => {},
            onCancel: () => {},
          ),
        ) ??
        false;
  }

  Future<void> updateProfileImage(File? image) async {
    if (!InternetGuard.ensureOnline()) return;

    if (user.value == null) return;

    isImageLoading.value = true;
    try {
      final updatedUser = await _authRepo.updateProfile(
        firstName: user.value!.firstName,
        lastName: user.value!.lastName,
        email: user.value!.email,
        phone: user.value!.phone,
        address: user.value!.address,
        image: image,
      );
      _updateUser(updatedUser);
      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: image == null
            ? AppTexts.theImageHasBeenSuccessfullyDeleted
            : AppTexts.profileImageUpdated,
      );
    } catch (_) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: image == null
            ? AppTexts.failedToDeleteTheImage
            : AppTexts.imageUploadFailed,
      );
    } finally {
      isImageLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? address,
    File? image,
  }) async {
    if (!InternetGuard.ensureOnline()) return;

    if (user.value == null) return;

    isLoading.value = true;
    try {
      final updatedUser = await _authRepo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        image: image,
      );

      _updateUser(updatedUser);
      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.profileDataHasBeenSuccessfullyUpdated,
      );
      Get.back();
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: AppTexts.theProfileHasNotBeenUpdated,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUser(UserModel updatedUser) async {
    user.value = updatedUser;
    authController.user.value = updatedUser;
    await AuthService.saveUser(updatedUser.toJson());
  }
}
