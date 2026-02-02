// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class CustomCardSetting extends StatelessWidget {
  final String title;
  final List<String>? options;
  final String? currentValue;
  final void Function(String)? onSelected;
  final Widget? trailing;
  final IconData? iconData;

  const CustomCardSetting({
    super.key,
    required this.title,
    this.options,
    this.currentValue,
    this.onSelected,
    this.trailing,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          if (iconData != null)
            Icon(iconData, color: AppColors.primary, size: 16),
          if (iconData != null) const SizedBox(width: 8),

          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppThemeHelper.blackBblack(context),
            ),
          ),

          const Spacer(),

          if (trailing != null)
            trailing!
          else if (options != null && currentValue != null)
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // color: AppColors.white,
              elevation: 6,
              onSelected: onSelected,
              itemBuilder: (context) => options!.map((opt) {
                return PopupMenuItem<String>(
                  value: opt,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt.tr,
                        style: TextStyle(
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                      if (opt == currentValue)
                        Icon(
                          Icons.check,
                          color: AppThemeHelper.whiteBlack(context),
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentValue!.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppThemeHelper.blackBblack(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppThemeHelper.blackBblack(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
