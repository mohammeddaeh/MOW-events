import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class CustomCardSetting extends StatelessWidget {
  final String title;

  /// سطر ثانٍ بخط أصغر (اختياري).
  final String? subtitle;
  final List<String>? options;
  final String? currentValue;
  final void Function(String)? onSelected;
  final Widget? trailing;
  final IconData? iconData;
  final VoidCallback? onTap;

  const CustomCardSetting({
    super.key,
    required this.title,
    this.subtitle,
    this.options,
    this.currentValue,
    this.onSelected,
    this.trailing,
    this.iconData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String localizedOptionLabel(String value) =>
        DateLocalizationHelper.localizeDigits(value.tr);
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);
    final iconColor = AppThemeHelper.buttonPrimary(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.07),
                blurRadius: isDark ? 12 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (iconData != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.14 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 16),
                ),
              if (iconData != null) const SizedBox(width: 8),
              Expanded(
                child: subtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppThemeHelper.whiteBlack(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppThemeHelper.textSecondary(context),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else if (options != null && currentValue != null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  onSelected: onSelected,
                  itemBuilder: (context) => options!.map((opt) {
                    return PopupMenuItem<String>(
                      value: opt,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizedOptionLabel(opt),
                            style: TextStyle(
                              color: AppThemeHelper.whiteBlack(context),
                            ),
                          ),
                          if (opt == currentValue)
                            Icon(
                              Icons.check,
                              color: AppThemeHelper.buttonPrimary(context),
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
                        localizedOptionLabel(currentValue!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppThemeHelper.whiteBlack(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
