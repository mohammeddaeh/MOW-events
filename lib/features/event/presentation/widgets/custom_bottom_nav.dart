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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final baseHeight = 70.h;

    return Container(
      height: baseHeight + bottomPadding,
      decoration: BoxDecoration(
        color: AppThemeHelper.bottomNav(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(50),
            blurRadius: 15.r,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 12.0,
          bottom: bottomPadding + 8.0,
          left: 20.0,
          right: 20.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildNavItem(
                icon: AppImages.calendar,
                isSelected: currentIndex == 0,
                label: AppTexts.home,
                onTap: () => onTap(0),
              ),
            ),

            const SizedBox(width: 12),
            _buildAddButton(),
            const SizedBox(width: 12),

            Expanded(
              child: _buildNavItem(
                icon: AppImages.settings,
                isSelected: currentIndex == 1,
                label: AppTexts.settings,
                onTap: () => onTap(1),
              ),
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
          onTapDown: (_) => setState(() => scale = 0.9),
          onTapUp: (_) {
            setState(() => scale = 1.0);
            onTap();
          },
          onTapCancel: () => setState(() => scale = 1.0),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? AppThemeHelper.whitePrimary(context)
                        : AppColors.textGray,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                    color: isSelected
                        ? AppThemeHelper.whitePrimary(context)
                        : AppColors.textGray,
                    letterSpacing: 0.2,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;

        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.9),
          onTapUp: (_) {
            setState(() => scale = 1.0);
            if (!InternetGuard.ensureOnline()) return;
            Get.toNamed(AppRouter.addEventScreen);
          },
          onTapCancel: () => setState(() => scale = 1.0),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}
