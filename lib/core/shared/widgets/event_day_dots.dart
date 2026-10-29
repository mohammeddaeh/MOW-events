import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

/// نقاط أحداث اليوم بأسلوب تقويم الموبايل: نقطة لكل حدث بلون تصنيفه وبالترتيب
/// الذي تصل به [colors] (زمنياً)، تملأ العرض المتاح على [maxRows] صفوف.
/// عند الزحمة تصغر النقاط حتى [minDotSize]، وما لا يتسع يظهر "+n" في آخر الصف الأخير.
class EventDayDots extends StatelessWidget {
  final List<Color> colors;
  final double dotSize;
  final double spacing;
  final int maxRows;

  /// أصغر حجم تنكمش إليه النقطة عند كثرة الأحداث (افتراضياً 70% من [dotSize]).
  final double? minDotSize;

  /// إظهار "+n" عند عدم اتساع كل الأحداث (يُخفى في الخلايا الصغيرة جداً).
  final bool showOverflowCount;

  const EventDayDots({
    super.key,
    required this.colors,
    this.dotSize = 6,
    this.spacing = 2,
    this.maxRows = 2,
    this.minDotSize,
    this.showOverflowCount = true,
  });

  static int _perRow(double width, double dot, double gap) =>
      max(1, ((width + gap) / (dot + gap)).floor());

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    // حدث بدون تصنيف (لون شفاف) يأخذ اللون الافتراضي
    final all = [for (final c in colors) c.a == 0 ? AppColors.gold : c];
    final countStyle = TextStyle(
      fontSize: dotSize * 1.5,
      height: 1,
      fontWeight: FontWeight.w700,
      color: AppThemeHelper.textSecondary(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite) {
          return _buildRows([all], dotSize, spacing, null, countStyle);
        }

        var size = dotSize;
        var gap = spacing;
        // ننكمش فقط إذا لم تتسع كل النقاط بالحجم الأصلي على كل الصفوف
        if (_perRow(width, size, gap) * maxRows < all.length) {
          final minSize = minDotSize ?? dotSize * 0.7;
          gap = spacing * (minSize / dotSize);
          size = minSize;
        }

        final perRow = _perRow(width, size, gap);
        final capacity = perRow * maxRows;

        var shownCount = all.length;
        String? overflowLabel;
        if (all.length > capacity) {
          if (showOverflowCount) {
            // نحجز من آخر صف خانات تكفي عرض "+n"
            final label = _label(all.length);
            final labelWidth = (TextPainter(
              text: TextSpan(text: label, style: countStyle),
              textDirection: TextDirection.ltr,
            )..layout()).width;
            final slots = ((labelWidth + gap) / (size + gap)).ceil();
            shownCount = max(0, capacity - slots);
            overflowLabel = _label(all.length - shownCount);
          } else {
            shownCount = capacity;
          }
        }

        final shown = all.take(shownCount).toList();
        final rows = [
          for (var i = 0; i < shown.length; i += perRow)
            shown.sublist(i, min(i + perRow, shown.length)),
        ];
        if (rows.isEmpty) rows.add(const []);

        return _buildRows(rows, size, gap, overflowLabel, countStyle);
      },
    );
  }

  static String _label(int n) => DateLocalizationHelper.localizeDigits('+$n');

  Widget _buildRows(
    List<List<Color>> rows,
    double size,
    double gap,
    String? overflowLabel,
    TextStyle countStyle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows[r].length; i++)
                  Container(
                    width: size,
                    height: size,
                    margin: EdgeInsetsDirectional.only(
                      end:
                          i < rows[r].length - 1 ||
                              (overflowLabel != null && r == rows.length - 1)
                          ? gap
                          : 0,
                    ),
                    decoration: BoxDecoration(
                      color: rows[r][i],
                      shape: BoxShape.circle,
                    ),
                  ),
                if (overflowLabel != null && r == rows.length - 1)
                  Text(
                    overflowLabel,
                    textDirection: TextDirection.ltr,
                    style: countStyle,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
