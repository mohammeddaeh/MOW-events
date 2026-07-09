import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/theme/app_theme.dart';

/// خط التطبيق الافتراضي — يُستخدم مع [Text] و [RichText] و [DefaultTextStyle].
class AppTypography {
  AppTypography._();

  static TextStyle base(BuildContext context) {
    final theme = Theme.of(context);
    final fromTheme = theme.textTheme.bodyMedium;

    if (fromTheme != null) {
      return fromTheme.fontFamily == AppTheme.appFontFamily
          ? fromTheme
          : fromTheme.copyWith(fontFamily: AppTheme.appFontFamily);
    }

    return const TextStyle(fontFamily: AppTheme.appFontFamily);
  }

  static TextStyle merge(BuildContext context, TextStyle? style) {
    if (style == null) return base(context);
    return base(context).merge(style);
  }

  static TextSpan span(
    BuildContext context, {
    required String text,
    TextStyle? style,
    List<InlineSpan>? children,
  }) {
    return TextSpan(
      text: text,
      style: merge(context, style),
      children: children,
    );
  }
}
