import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/screens/settings_screen.dart';
import 'package:mow_events/features/event/presentation/widgets/custom_bottom_nav.dart';
import 'package:mow_events/features/event/presentation/widgets/home_tab.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = AppThemeHelper.bottomNav(context);
    final navIconBrightness = isDark ? Brightness.light : Brightness.dark;

    final overlayStyle =
        (isDark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                  ))
            .copyWith(
              systemNavigationBarColor: navBarColor,
              systemNavigationBarIconBrightness: navIconBrightness,
              systemNavigationBarDividerColor: Colors.transparent,
            );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
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
