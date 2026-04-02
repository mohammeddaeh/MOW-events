// import 'package:flutter/material.dart';
// import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
// import 'package:mow_events/core/utils/validator/validator.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:intl_phone_number_input/intl_phone_number_input.dart';
// import 'package:mow_events/core/utils/constants/app_texts.dart';
// import 'package:mow_events/core/utils/helpers/helper_functions.dart';

// class InternationalPhoneNumberInputField extends StatelessWidget {
//   const InternationalPhoneNumberInputField({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // final controller = Get.put(OnBoardingController());
//     final tController = Get.put(LoginController());

//     return Obx(
//       () => InternationalPhoneNumberInput(
//         autoValidateMode: AutovalidateMode.onUserInteraction,
//         validator: (value) => AppValidator.validatePhoneNumber(value),
//         inputDecoration: InputDecoration(
//           labelText: AppTexts.phoneNo,
//           prefixIcon: const Icon(Iconsax.call),
//         ),
//         searchBoxDecoration: InputDecoration(
//           labelText: AppTexts.searchCountry,
//           prefixIcon: const Icon(Iconsax.global_search),
//         ),
//         locale: AppHelper.currentLang,
//         // initialValue: PhoneNumber(isoCode: controller.countryCode.value),
//         selectorConfig: const SelectorConfig(
//           selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
//           useBottomSheetSafeArea: true,
//         ),
//         onInputChanged: (PhoneNumber number) {
//           tController.phoneNumber.value = number.phoneNumber ?? '';
//         },
//       ),
//     );
//   }
// }
