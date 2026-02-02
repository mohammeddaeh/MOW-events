// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mow_events/features/auth/screen/login_screen.dart';

// class OnBoardingController extends GetxController {
//   static OnBoardingController get instance => Get.find();

//   // Variables
//   final pageController = PageController();
//   RxInt currentPageIndex = 0.obs;
//   RxString countryCode = 'SY'.obs;

//   // Update Current Index When Screen Scrolled
//   void updatePageIndicator(int index) => currentPageIndex.value = index;

//   // Jump To The Specific Dot Selected Screen.
//   void dotNavigationClick(int index) {
//     currentPageIndex.value = index;
//     pageController.jumpToPage(index);
//   }

//   // Update Current Index & jump to next page
//   void nextPage() async {
//     // If Last Screen Show Full Screen Loader While Getting Country Code
//     if (currentPageIndex.value == 2) {
//       Get.offAll(() => const LoginScreen());
//     } else {
//       // Else Jump To The Next Screen
//       int page = currentPageIndex.value + 1;
//       pageController.jumpToPage(page);
//     }
//   }

//   // Update Current Index & Jump To The Last Screen
//   void skipPage() {
//     currentPageIndex.value = 2;
//     pageController.jumpToPage(2);
//   }
// }
