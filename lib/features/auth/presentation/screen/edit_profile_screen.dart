import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/change_profile_image_sheet.dart';
import 'package:mow_events/features/auth/presentation/widgets/profile_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileController controller;
  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController addressCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    firstNameCtrl = TextEditingController();
    lastNameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    addressCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillUserData());
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  void _fillUserData() {
    final user = controller.user.value;
    if (user == null) return;
    firstNameCtrl.text = user.firstName;
    lastNameCtrl.text = user.lastName;
    emailCtrl.text = user.email;
    phoneCtrl.text = AppValidator.normalizePhoneNumber(user.phone);
    addressCtrl.text = user.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppThemeHelper.background(context);
    final textColor = AppThemeHelper.whiteBlack(context);
    final borderColor = AppThemeHelper.border(context);
    final buttonColor = AppThemeHelper.buttonPrimary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppTexts.editProfile, style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: AppThemeHelper.blackWhite(context),
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => ProfileImage(
                    text: AppTexts.updateYourPersonalInformation,
                    imageUrl: controller.user.value?.image,
                    editable: true,
                    onChangeImage: () => Get.bottomSheet(
                      ChangeProfileImageSheet(),
                      isScrollControlled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AdaptiveFormField(
                  controller: firstNameCtrl,
                  type: AdaptiveFieldType.text,
                  label: AppTexts.firstName,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: AppValidator.required,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                AdaptiveFormField(
                  controller: lastNameCtrl,
                  type: AdaptiveFieldType.text,
                  label: AppTexts.familyName,
                  prefixIcon: const Icon(Icons.person),
                  validator: AppValidator.required,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                AdaptiveFormField(
                  controller: emailCtrl,
                  type: AdaptiveFieldType.email,
                  label: AppTexts.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: AppValidator.required,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                AdaptiveFormField(
                  controller: phoneCtrl,
                  type: AdaptiveFieldType.phone,
                  label: AppTexts.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_android),
                  validator: AppValidator.validatePhoneNumber,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                AdaptiveFormField(
                  controller: addressCtrl,
                  type: AdaptiveFieldType.note,
                  label: AppTexts.addresse,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  borderColor: borderColor,
                ),
                const SizedBox(height: 32),
                Obx(
                  () => SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final normalizedPhone =
                                  AppValidator.normalizePhoneNumber(
                                    phoneCtrl.text,
                                  );
                              await controller.updateProfile(
                                firstName: firstNameCtrl.text.trim(),
                                lastName: lastNameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                phone: normalizedPhone,
                                address: addressCtrl.text.trim().isEmpty
                                    ? null
                                    : addressCtrl.text.trim(),
                              );
                            },
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(AppTexts.saveChanges),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
