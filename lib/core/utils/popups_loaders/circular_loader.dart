import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/helper_functions.dart';

class AppCircularLoader extends StatelessWidget {
  const AppCircularLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppHelper.isDarkMode ? AppColors.white : AppColors.primary;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: AppSizes.s56),
        child: CircularProgressIndicator(color: color),
      ),
    );
  }
}
