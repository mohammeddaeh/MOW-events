import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

class MonthEventsBottomSheet extends StatelessWidget {
  final String monthTitle;
  final List<EventModel> events;

  const MonthEventsBottomSheet({
    super.key,
    required this.monthTitle,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppThemeHelper.border(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '${AppTexts.events} $monthTitle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Text(
                          AppTexts.thereAreNoEventsThisMonth,
                          style: TextStyle(
                            color: AppThemeHelper.textSecondary(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: AppThemeHelper.border(context)),
                        itemBuilder: (_, i) {
                          final e = events[i];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.event,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                e.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppThemeHelper.whiteBlack(context),
                                ),
                              ),
                              subtitle: Text(
                                '${e.startTime} - ${e.endTime}',
                                style: TextStyle(
                                  color: AppThemeHelper.textSecondary(context),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
