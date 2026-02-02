// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppThemeHelper.bottomNav(context),

        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(40),
            blurRadius: 10.r,
            offset: const Offset(0, 0),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: AppImages.calendar,
              isSelected: currentIndex == 0,
              label: AppTexts.home,
              onTap: () => onTap(0),
            ),

            _buildAddButton(),

            _buildNavItem(
              icon: AppImages.settings,
              isSelected: currentIndex == 1,
              label: AppTexts.settings,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;

        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.85),
          onTapUp: (_) {
            setState(() => scale = 1.0);
            onTap();
          },
          onTapCancel: () => setState(() => scale = 1.0),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  icon,
                  color: isSelected
                      ? AppThemeHelper.whitePrimary(context)
                      : AppColors.textGray,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                    color: isSelected
                        ? AppThemeHelper.whitePrimary(context)
                        : AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Container(
      height: 50,
      width: 50,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          if (!InternetGuard.ensureOnline()) return;

          // Get.to(() => AddEventPagسسe());
          Get.toNamed(AppRouter.addEventScreen);
        },
      ),
    );
  }
}
