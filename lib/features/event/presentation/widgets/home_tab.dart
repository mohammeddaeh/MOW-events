// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/screens/day_screen.dart';
import 'package:mow_events/features/event/presentation/screens/month_screen.dart';
import 'package:mow_events/features/event/presentation/screens/week_screen.dart';
import 'package:mow_events/features/event/presentation/screens/year_screen.dart';
import 'package:mow_events/core/shared/widgets/icon_notifications.dart';
import 'package:mow_events/features/event/presentation/widgets/filter_button.dart';

class HomeTab extends StatelessWidget {
  final HomeController controller;
  const HomeTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return SafeArea(
      child: Column(
        children: [
          _buildSearchHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.tabController,
              children: [
                DayScreen(),
                WeekScreen(),
                MonthScreen(),
                YearScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const IconNotifications(),
          SizedBox(width: 14.w),
          Expanded(
            child: SizedBox(
              height: 40.h,
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: AppTexts.search,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  hintText: AppTexts.search,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      AppImages.search,
                      color: AppColors.gold,
                    ),
                  ),
                  filled: true,

                  fillColor: isDark
                      ? Colors.grey.shade900
                      : AppColors.backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          FilterButton(controller: controller),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: controller.tabController,
      labelColor: AppColors.gold,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.gold,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      tabs: [
        Tab(text: AppTexts.day),
        Tab(text: AppTexts.week),
        Tab(text: AppTexts.month),
        Tab(text: AppTexts.year),
      ],
    );
  }
}
