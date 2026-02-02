// import 'package:flutter/material.dart';
// import 'package:mow_events/features/on_boarding/controller/onboarding_controller.dart';
// import 'package:mow_events/core/utils/constants/sizes.dart';
// import 'package:mow_events/core/utils/constants/text_strings.dart';
// import 'package:mow_events/core/utils/device/device_utility.dart';
// import 'package:mow_events/core/utils/helpers/helper_functions.dart';

// class OnBoardingSkip extends StatelessWidget {
//   const OnBoardingSkip({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: AppDeviceUtils.appBarHeight,
//       right: AppHelper.isRtl ? null : AppSizes.defaultSpace,
//       left: AppHelper.isRtl ? AppSizes.defaultSpace : null,
//       child: TextButton(
//         onPressed: OnBoardingController.instance.skipPage,
//         child: Text(AppTexts.skip),
//       ),
//     );
//   }
// }
