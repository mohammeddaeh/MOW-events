import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/change_profile_image_sheet.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_image.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_section.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppThemeHelper.background(context);
    final textColor = AppThemeHelper.whiteBlack(context);
    final sectionColor = AppThemeHelper.blackWhite(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppTexts.profile, style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: sectionColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Obx(() {
        final user = controller.user.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileImage(
                  text: user?.fullName,
                  imageUrl: user?.image,
                  onChangeImage: () => Get.bottomSheet(
                    ChangeProfileImageSheet(),
                    isScrollControlled: true,
                  ),
                ),
                const SizedBox(height: 18),

                ProfileSection(
                  title: AppTexts.personalInformation,
                  backgroundColor: sectionColor,
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
                  backgroundColor: sectionColor,
                  children: [
                    ProfileInfoTile(label: AppTexts.email, value: user?.email),
                    ProfileInfoTile(
                      label: AppTexts.phoneNo,
                      value: user?.phone,
                    ),
                  ],
                ),
                ProfileSection(
                  title: AppTexts.workInformation,
                  backgroundColor: sectionColor,
                  children: [
                    ProfileInfoTile(
                      label: AppTexts.section,
                      value: user?.department?.name,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeHelper.buttonPrimary(context),
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
                    label: Text(
                      AppTexts.editProfile,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// class ProfileScreen extends GetView<ProfileController> {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(AppTexts.profile), centerTitle: true),
//       body: Obx(() {
//         final user = controller.user.value;

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ProfileImage(
//                 text: user?.fullName,
//                 imageUrl: user?.image,
//                 onChangeImage: () => Get.bottomSheet(
//                   ChangeProfileImageSheet(),
//                   isScrollControlled: true,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               ProfileSection(
//                 title: AppTexts.personalInformation,
//                 children: [
//                   ProfileInfoTile(
//                     label: AppTexts.firstName,
//                     value: user?.firstName,
//                   ),
//                   ProfileInfoTile(
//                     label: AppTexts.familyName,
//                     value: user?.lastName,
//                   ),
//                 ],
//               ),
//               ProfileSection(
//                 title: AppTexts.contactInformation,
//                 children: [
//                   ProfileInfoTile(label: AppTexts.email, value: user?.email),
//                   ProfileInfoTile(label: AppTexts.phoneNo, value: user?.phone),
//                 ],
//               ),
//               ProfileSection(
//                 title: AppTexts.workInformation,
//                 children: [
//                   ProfileInfoTile(
//                     label: AppTexts.section,
//                     value: user?.department?.name,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               SizedBox(
//                 height: 52,
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     if (!InternetGuard.ensureOnline()) return;
//                     Get.toNamed(AppRouter.editProfile);
//                   },
//                   icon: const Icon(Icons.edit),
//                   label: Text(AppTexts.editProfile),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
