import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_image.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_section.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppThemeHelper.background(context);
    final textColor = AppThemeHelper.whiteBlack(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppTexts.profile, style: TextStyle(color: textColor)),
        centerTitle: true,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Obx(() {
        final user = controller.user.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileImage(
                  text: user?.fullName,
                  imageUrl: user?.image,
                  editable: false,
                ),
                const SizedBox(height: 8),

                ProfileSection(
                  title: AppTexts.personalInformation,
                  children: [
                    ProfileInfoTile(
                      label: AppTexts.firstName,
                      value: user?.firstName,
                    ),
                    ProfileInfoTile(
                      label: AppTexts.familyName,
                      value: user?.lastName,
                    ),
                  ],
                ),
                ProfileSection(
                  title: AppTexts.contactInformation,
                  children: [
                    ProfileInfoTile(label: AppTexts.email, value: user?.email),
                    ProfileInfoTile(
                      label: AppTexts.phoneNo,
                      value: user?.phone,
                    ),
                    ProfileInfoTile(
                      label: AppTexts.addresse,
                      value: user?.address,
                    ),
                  ],
                ),
                ProfileSection(
                  title: AppTexts.workInformation,
                  children: [
                    ProfileInfoTile(
                      label: AppTexts.section,
                      value: user?.department?.name,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: [
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeHelper.buttonPrimary(
                            context,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          if (!InternetGuard.ensureOnline()) return;
                          Get.toNamed(AppRouter.editProfile);
                        },
                        icon: const Icon(Icons.edit, size: 20),
                        label: Text(AppTexts.editProfile),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (!InternetGuard.ensureOnline()) return;
                          Get.toNamed(AppRouter.changePassword);
                        },
                        icon: const Icon(Icons.lock_reset_rounded, size: 20),
                        label: Text(AppTexts.changePassword),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppThemeHelper.buttonPrimary(
                            context,
                          ),
                          side: BorderSide(
                            color: AppThemeHelper.buttonPrimary(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
