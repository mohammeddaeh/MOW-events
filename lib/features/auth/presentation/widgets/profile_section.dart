import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;

  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppThemeHelper.blackWhite(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppThemeHelper.whiteBlack(context),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry? padding;

  const ProfileInfoTile({
    super.key,
    required this.label,
    this.value,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style:
                  labelStyle ??
                  TextStyle(
                    color: AppThemeHelper.whiteBlack(context),
                    fontSize: 14,
                  ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value ?? '-',
              style:
                  valueStyle ??
                  TextStyle(
                    color: AppThemeHelper.whiteBlack(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
