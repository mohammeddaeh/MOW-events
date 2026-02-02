// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const IconNotifications(),

          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) {
                  controller.searchQuery.value = v;
                },
                decoration: InputDecoration(
                  hintText: AppTexts.search,
                  prefixIcon: SvgPicture.asset(
                    AppImages.search,
                    fit: BoxFit.scaleDown,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
