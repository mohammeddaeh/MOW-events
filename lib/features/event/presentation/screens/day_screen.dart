import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/core/shared/widgets/refreshable_empty_list.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/day_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_sheet.dart';

class DayScreen extends GetView<DayController> {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.end,
        //     children: [
        //       TextButton.icon(
        //         onPressed: () {
        //           showModalBottomSheet<void>(
        //             context: context,
        //             isScrollControlled: true,
        //             shape: const RoundedRectangleBorder(
        //               borderRadius:
        //                   BorderRadius.vertical(top: Radius.circular(24)),
        //             ),
        //             builder: (_) => const ScheduledAlertsSheet(),
        //           );
        //         },
        //         icon: Icon(
        //           Icons.schedule_rounded,
        //           size: 20,
        //           color: AppThemeHelper.accent(context),
        //         ),
        //         label: Text(AppTexts.scheduledAlerts),
        //         style: TextButton.styleFrom(
        //           foregroundColor: AppThemeHelper.accent(context),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Expanded(
          child: Obx(() {
            final events = controller.events;

            return RefreshableList(
              onRefresh: () async {
                await homeController.refreshAllEvents();
              },
              emptyWidget: EmptyStateWidget(
                lottieAsset: AppImages.noResult,
                title: AppTexts.noEventsThisDay,
              ),
              children: events
                  .map(
                    (e) => CardEvent(event: e, homeController: homeController),
                  )
                  .toList(),
            );
          }),
        ),
      ],
    );
  }
}
