import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/screens/settings_screen.dart';
import 'package:mow_events/features/event/presentation/widgets/custom_bottom_nav.dart';
import 'package:mow_events/features/event/presentation/widgets/home_tab.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Obx(
        () => Scaffold(
          body: controller.currentIndex.value == 0
              ? HomeTab(controller: controller)
              : SettingsScreen(),

          bottomNavigationBar: CustomBottomNav(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeBottomIndex,
          ),
        ),
      ),
    );
  }
}
