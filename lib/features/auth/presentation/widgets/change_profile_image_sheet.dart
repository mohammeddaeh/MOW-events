import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';

import '../../../../core/utils/constants/enums/app_dialog_type.dart';

class ChangeProfileImageSheet extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  ChangeProfileImageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeHelper.blackWhite(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppTexts.changeProfilePicture),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(AppTexts.takeAPhoto),
            onTap: () {
              controller.pickImageFromCamera();
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(AppTexts.selectionFromTheGallery),
            onTap: () {
              controller.pickImageFromGallery();
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(AppTexts.deleteTheImage),
            onTap: () async {
              Get.back();

              if (controller.user.value?.image == null ||
                  controller.user.value!.image!.isEmpty) {
                Get.snackbar(
                  AppTexts.alert,
                  AppTexts.thereIsNoImageToDelete,
                  backgroundColor: Colors.grey[900],
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
                return;
              }

              await showAppDialog(
                context: Get.context!,
                type: AppDialogType.delete,
                onConfirm: () async {
                  await controller.updateProfileImage(null);
                },
                onCancel: () {},
              );
            },
          ),
        ],
      ),
    );
  }
}
