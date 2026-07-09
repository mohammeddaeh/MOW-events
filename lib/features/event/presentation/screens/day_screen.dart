import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/core/shared/widgets/pagination_footer.dart';
import 'package:mow_events/core/shared/widgets/refreshable_empty_list.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/day_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';

class DayScreen extends GetView<DayController> {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Obx(() {
            final events = controller.events;
            final visibleEvents = controller.visibleEvents;
            final shouldShowFooter = events.isNotEmpty;

            return RefreshableList(
              onRefresh: () async {
                await homeController.refreshAllEvents();
              },
              emptyWidget: EmptyStateWidget(
                lottieAsset: AppImages.noResult,
                title: AppTexts.noEventsThisDay,
              ),
              children: visibleEvents
                  .map(
                    (e) => CardEvent(
                      event: e,
                      homeController: homeController,
                      config: EventCardConfig(
                        showMultiDaySpanHint:
                            EventDayListHelper.spansMultipleCalendarDays(e),
                      ),
                    ),
                  )
                  .toList(),
              footer: shouldShowFooter
                  ? Obx(
                      () => PaginationFooter(
                        isLoadingMore: homeController.isLoadingMoreEvents.value,
                        hasMore:
                            controller.canLoadMore ||
                            homeController.hasMoreEvents.value,
                        actionLabel: AppTexts.viewmore,
                        loadingLabel: AppTexts.loadingMoreEvents,
                        completedLabel: AppTexts.allEventsLoaded,
                        onLoadMore: controller.canLoadMore
                            ? controller.loadMore
                            : homeController.loadMoreEvents,
                      ),
                    )
                  : null,
            );
          }),
        ),
      ],
    );
  }
}
