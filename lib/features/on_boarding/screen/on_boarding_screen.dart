// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mow_events/features/on_boarding/controller/onboarding_controller.dart';
// import 'package:mow_events/core/shared/app_default_page.dart';
// import 'package:mow_events/core/utils/constants/app_images.dart';
// import 'package:mow_events/core/utils/constants/text_strings.dart';
// import 'package:mow_events/features/on_boarding/widgets/on_boarding_change_lang.dart';
// import 'package:mow_events/features/on_boarding/widgets/on_boarding_dot_navigation.dart';
// import 'package:mow_events/features/on_boarding/widgets/on_boarding_next_button.dart';
// import 'package:mow_events/features/on_boarding/widgets/on_boarding_skip.dart';

// class OnBoardingScreen extends StatelessWidget {
//   const OnBoardingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(OnBoardingController());

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: Stack(
//         children: [
//           // Horizontal Scrollabe Pages
//           PageView(
//             controller: controller.pageController,
//             onPageChanged: controller.updatePageIndicator,
//             children: [
//               AppDefaultPage(
//                 image: AppImages.logoAndName,
//                 title: AppTexts.onBoardingTitle1,
//                 subTitle: AppTexts.onBoardingSubTitle1,
//               ),
//               AppDefaultPage(
//                 image: AppImages.calendar,
//                 title: AppTexts.onBoardingTitle2,
//                 subTitle: AppTexts.onBoardingSubTitle2,
//               ),
//               AppDefaultPage(
//                 image: AppImages.clock,
//                 title: AppTexts.onBoardingTitle3,
//                 subTitle: AppTexts.onBoardingSubTitle3,
//               ),
//             ],
//           ),

//           // Skip Button
//           const OnBoardingSkip(),

//           // Change Language Button
//           const OnBoardingChangeLang(),

//           // Dot Navigaton SmoothPageIndicator
//           const OnBoardingDotNavigation(),

//           // Circular Button
//           const OnBoardingNextButton(),
//         ],
//       ),
//     );
//   }
// }
