import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/core/shared/widgets/pagination_footer.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/year_controller.dart';

class MonthEventsBottomSheet extends StatefulWidget {
  static const int pageSize = 10;

  final String monthTitle;
  final DateTime month;
  final ValueChanged<EventModel>? onEventTap;

  const MonthEventsBottomSheet({
    super.key,
    required this.monthTitle,
    required this.month,
    this.onEventTap,
  });

  @override
  State<MonthEventsBottomSheet> createState() => _MonthEventsBottomSheetState();
}

class _MonthEventsBottomSheetState extends State<MonthEventsBottomSheet> {
  int _visibleCount = MonthEventsBottomSheet.pageSize;

  void _loadMoreLocal(int total) {
    setState(() {
      _visibleCount = math.min(
        _visibleCount + MonthEventsBottomSheet.pageSize,
        total,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YearController>();
    final homeController = Get.find<HomeController>();
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
                '${AppTexts.events} ${widget.monthTitle}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Obx(() {
                  final sortedEvents = List<EventModel>.from(
                    controller.getEventsForMonth(widget.month),
                  )
                    ..sort(
                      (a, b) => (a.startDateTimeSafe ?? DateTime(2100))
                          .compareTo(b.startDateTimeSafe ?? DateTime(2100)),
                    );

                  if (sortedEvents.isEmpty) {
                    return EmptyStateWidget(
                      lottieAsset: AppImages.noResult,
                      title: AppTexts.thereAreNoEventsThisMonth,
                    );
                  }

                  final clampedVisibleCount = math.min(
                    _visibleCount,
                    sortedEvents.length,
                  );
                  final visibleEvents = sortedEvents
                      .take(clampedVisibleCount)
                      .toList(growable: false);
                  final canLoadMoreLocal =
                      clampedVisibleCount < sortedEvents.length;

                  return ListView.separated(
                    itemCount: visibleEvents.length + 1,
                    separatorBuilder: (_, __) =>
                        Divider(color: AppThemeHelper.border(context)),
                    itemBuilder: (_, i) {
                      if (i >= visibleEvents.length) {
                        return PaginationFooter(
                          isLoadingMore: homeController.isLoadingMoreEvents.value,
                          hasMore:
                              canLoadMoreLocal ||
                              homeController.hasMoreEvents.value,
                          actionLabel: AppTexts.viewmore,
                          loadingLabel: AppTexts.loadingMoreEvents,
                          completedLabel: AppTexts.allEventsLoaded,
                          onLoadMore: canLoadMoreLocal
                              ? () => _loadMoreLocal(sortedEvents.length)
                              : homeController.loadMoreEvents,
                        );
                      }

                      final e = visibleEvents[i];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: widget.onEventTap == null
                              ? null
                              : () => widget.onEventTap!(e),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.event,
                            color: AppColors.buttonDisabled,
                          ),
                          title: Text(
                            e.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppThemeHelper.whiteBlack(context),
                            ),
                          ),
                          trailing: widget.onEventTap == null
                              ? null
                              : Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppThemeHelper.textSecondary(context),
                                ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
