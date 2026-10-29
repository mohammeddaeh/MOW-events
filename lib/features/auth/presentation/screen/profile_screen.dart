import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_image.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_section.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  Future<void> _copyToClipboard({
    required String value,
    required String message,
  }) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    AppSnackBars.successSnackBar(title: AppTexts.copied, message: message);
  }

  Widget _buildCopyAction({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return InkResponse(
      onTap: onPressed,
      radius: 14,
      highlightShape: BoxShape.circle,
      containedInkWell: false,
      hoverColor: primary.withValues(alpha: 0.08),
      splashColor: primary.withValues(alpha: 0.12),
      child: Tooltip(
        message: AppTexts.copy,
        child: SizedBox(
          width: 20,
          height: 20,
          child: Icon(Icons.copy_rounded, size: 15, color: primary),
        ),
      ),
    );
  }

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
        final fullName = (user?.fullName ?? '').trim();
        final email = (user?.email ?? '').trim();
        final phone = (user?.phone ?? '').trim();

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
                const SizedBox(height: 12),

                ProfileSection(
                  title: AppTexts.personalInformation,
                  children: [
                    ProfileInfoTile(
                      label: AppTexts.fullName,
                      value: user?.fullName,
                      trailing: fullName.isEmpty
                          ? null
                          : _buildCopyAction(
                              context: context,
                              onPressed: () => _copyToClipboard(
                                value: fullName,
                                message:
                                    AppTexts.theFullNameWasCopiedToTheClipboard,
                              ),
                            ),
                    ),
                  ],
                ),
                ProfileSection(
                  title: AppTexts.contactInformation,
                  children: [
                    ProfileInfoTile(
                      label: AppTexts.email,
                      value: user?.email,
                      trailing: email.isEmpty
                          ? null
                          : _buildCopyAction(
                              context: context,
                              onPressed: () => _copyToClipboard(
                                value: email,
                                message:
                                    AppTexts.theEmailWasCopiedToTheClipboard,
                              ),
                            ),
                    ),
                    ProfileInfoTile(
                      label: AppTexts.phoneNo,
                      value: user?.phone,
                      trailing: phone.isEmpty
                          ? null
                          : _buildCopyAction(
                              context: context,
                              onPressed: () => _copyToClipboard(
                                value: phone,
                                message:
                                    AppTexts.thePhoneWasCopiedToTheClipboard,
                              ),
                            ),
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
                    if (user != null)
                      ProfileInfoTile(
                        label: AppTexts.role,
                        value: AppTexts.userRoleLabel(
                          isManager: user.isManager,
                          department: user.department?.name,
                        ),
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
