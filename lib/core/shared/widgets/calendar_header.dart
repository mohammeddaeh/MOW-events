import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime date;
  final String userCalendar;
  final double? scale;
  final bool showYear;
  final bool vertical;

  final bool showYearWithMonth;

  const CalendarHeader({
    super.key,
    required this.date,
    required this.userCalendar,
    this.scale,
    this.showYear = false,
    this.vertical = false,
    this.showYearWithMonth = false,
  });

  @override
  Widget build(BuildContext context) {
    final double fontScale = scale ?? 16;

    if (showYearWithMonth) {
      return _buildYearOnSidesHeader(fontScale);
    }

    return _buildNormalHeader(fontScale);
  }

  Widget _buildYearOnSidesHeader(double fontScale) {
    final gYear = DateLocalizationHelper.gYear(date);
    final gMonth = DateLocalizationHelper.gMonth(date);

    final hijriMonths =
        DateLocalizationHelper.getHijriMonthsRangeForGregorianMonth(date);
    final hMonth = DateLocalizationHelper.hijriMonthsAr[hijriMonths.first - 1];

    final hYear = DateLocalizationHelper.hYear(date);
    if (userCalendar == 'both') {
      return _buildBothHeader(fontScale);
    }

    if (userCalendar == 'gregorian') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$gMonth        $gYear",
            style: TextStyle(
              fontSize: fontScale * 1.6,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      );
    }

    if (userCalendar == 'hijri') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$hMonth        $hYear",
            style: TextStyle(
              fontSize: fontScale * 1.6,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNormalHeader(double fontScale) {
    final List<Widget> children = [];

    if (showYear) {
      String yearText;
      if (userCalendar == 'gregorian') {
        yearText = '${DateLocalizationHelper.gYear(date)} م';
      } else if (userCalendar == 'hijri') {
        yearText = '${DateLocalizationHelper.hYear(date)} هـ';
      } else {
        yearText =
            '${DateLocalizationHelper.gYear(date)} م              ${DateLocalizationHelper.hYear(date)} هـ';
      }

      children.add(
        Text(
          yearText,
          style: TextStyle(
            fontSize: fontScale * 1.3,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      );
    } else {
      if (userCalendar != 'hijri') {
        children.add(
          Text(
            DateLocalizationHelper.gMonth(date),
            style: TextStyle(
              fontSize: fontScale * 1.7,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        );
      }

      if (userCalendar == 'both') children.add(const SizedBox(width: 6));

      if (userCalendar != 'gregorian') {
        List<int> hijriMonths =
            DateLocalizationHelper.getHijriMonthsRangeForGregorianMonth(date);

        if (userCalendar == 'hijri') {
          children.add(
            Text(
              DateLocalizationHelper.hijriMonthsAr[hijriMonths.first - 1],
              style: TextStyle(
                fontSize: fontScale * 1.7,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          );
        } else {
          children.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateLocalizationHelper.hijriMonthsAr[hijriMonths.first - 1],
                  style: TextStyle(
                    fontSize: fontScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade700,
                  ),
                ),
                if (hijriMonths.length > 1)
                  Text(
                    ' _ ${DateLocalizationHelper.hijriMonthsAr[hijriMonths.last - 1]}',
                    style: TextStyle(
                      fontSize: fontScale,
                      fontWeight: FontWeight.w400,
                      color: Colors.amber.shade400,
                    ),
                  ),
              ],
            ),
          );
        }
      }
    }

    if (vertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children
            .map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: w,
              ),
            )
            .toList(),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.start, children: children);
  }

  Widget _buildBothHeader(double fontScale) {
    final gYear = DateLocalizationHelper.gYear(date);
    final gMonth = DateLocalizationHelper.gMonth(date);

    final hijriMonths =
        DateLocalizationHelper.getHijriMonthsRangeForGregorianMonth(date);
    final hMonth = DateLocalizationHelper.hijriMonthsAr[hijriMonths.first - 1];
    final hMonth2 = hijriMonths.length > 1
        ? DateLocalizationHelper.hijriMonthsAr[hijriMonths.last - 1]
        : null;

    final hYear = DateLocalizationHelper.hYear(date);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            gYear,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: fontScale * .95,
              fontWeight: FontWeight.w700,
              color: Colors.amber,
            ),
          ),
        ),

        Expanded(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gMonth,
                  style: TextStyle(
                    fontSize: fontScale * 1.3,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hMonth + (hMonth2 != null ? "  -  $hMonth2" : ""),
                  style: TextStyle(
                    fontSize: fontScale * .95,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 2,
          child: Text(
            hYear,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: fontScale * .95,
              fontWeight: FontWeight.w700,
              color: Colors.amber.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
