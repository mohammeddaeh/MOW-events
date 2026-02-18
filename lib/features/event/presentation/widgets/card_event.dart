// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/bindings/edit_event_binding.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/event/presentation/screens/edit_event_screen.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_sheet.dart';

class EventCardConfig {
  final bool enableTap;
  final bool showBottomSheet;
  final bool showMembers;
  final bool showPrivacy;
  final bool showCategory;
  final bool showReadMore;

  const EventCardConfig({
    this.enableTap = true,
    this.showBottomSheet = true,
    this.showMembers = false,
    this.showPrivacy = false,
    this.showCategory = true,
    this.showReadMore = true,
  });
}

extension EventDateFormatter on EventModel {
  bool get isSameDay {
    final start = startDateTimeSafe;
    final end = endDateTimeSafe;
    if (start == null || end == null) return false;
    return start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
  }

  String get startTimeHM {
    final start = startDateTimeSafe;
    return start != null ? DateFormat('HH:mm').format(start) : '--:--';
  }

  String get endTimeHM {
    final end = endDateTimeSafe;
    return end != null ? DateFormat('HH:mm').format(end) : '--:--';
  }

  String get startDateTimeFormatted {
    final start = startDateTimeSafe;
    return start != null ? DateFormat('dd MMM • HH:mm').format(start) : '--';
  }

  String get endDateTimeFormatted {
    final end = endDateTimeSafe;
    return end != null ? DateFormat('dd MMM • HH:mm').format(end) : '--';
  }
}

extension ReminderUIExtensions on ReminderController {
  void openEventReminders(BuildContext context, EventModel event) {
    final eventId = event.id.toString();
    final eventReminders = remindersMap[eventId] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EventRemindersSheet(
        event: event,
        reminders: eventReminders.obs,
        now: DateTime.now(),
      ),
    );
  }
}

class CardEvent extends StatelessWidget {
  final EventModel event;
  final HomeController homeController;
  final EventCardConfig config;
  final VoidCallback? onTap;

  const CardEvent({
    super.key,
    required this.event,
    required this.homeController,
    this.onTap,
    this.config = const EventCardConfig(),
  });

  bool get canEdit =>
      event.isPrivate == 1 || (event.isPublic == 1 && homeController.isAdmin);

  bool get canDelete => canEdit;
  Color getCategoryColor() {
    if (event.category == null || event.category!.color.isEmpty) {
      return Colors.transparent;
    }
    try {
      return Color(int.parse(event.category!.color.replaceAll('#', '0xff')));
    } catch (e) {
      return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = event.id.toString();

    if (event.name.trim().isEmpty || event.description.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final reminders = ReminderController.to.remindersMap[eventId] ?? [];

    return GestureDetector(
      onTap: () => _showFullText(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: AppThemeHelper.blackWhite(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeHelper.whiteBlack(context).withOpacity(0.15),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: event.isSameDay
                      ? Text(
                          '${event.startTimeHM} - ${event.endTimeHM}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 14,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.startDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.stop, size: 14, color: AppColors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.endDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                if (reminders.isNotEmpty)
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ReminderController.to.openEventReminders(context, event);
                    },
                    icon: Icon(
                      Icons.alarm,
                      size: 18.h,
                      color: AppThemeHelper.gold(context),
                    ),
                  ),

                if (canEdit || canDelete)
                  PopupMenuButton(
                    menuPadding: EdgeInsets.all(10),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),

                    icon: const Icon(Icons.more_horiz),
                    itemBuilder: (context) => [
                      if (canEdit)
                        PopupMenuItem(
                          child: Text(AppTexts.edit),
                          onTap: () {
                            Get.to(
                              () => const EditEventScreen(),
                              arguments: event,
                              binding: EditEventBinding(),
                            );
                          },
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          child: Text(
                            AppTexts.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                          onTap: () => homeController.confirmDelete(event),
                        ),
                    ],
                  ),
              ],
            ),
            Row(
              children: [
                if (event.category != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: getCategoryColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                SizedBox(width: 24),
                Expanded(
                  child: Text(
                    event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeHelper.textSecondary(context),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: AppColors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullText(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: BoxDecoration(
            color: AppThemeHelper.blackWhite(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  // color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.status,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _DetailCard(
                        icon: Icons.calendar_today,
                        title: AppTexts.timeAndDate,
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 14,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.startDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.stop, size: 14, color: AppColors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.endDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        iconColor: AppColors.blue,
                      ),

                      if (event.location.isNotEmpty)
                        _DetailCard(
                          icon: Icons.location_on,
                          title: AppTexts.theSite,
                          value: event.location,
                          iconColor: AppColors.red,
                        ),

                      if (event.category != null)
                        _DetailCard(
                          icon: Icons.label,
                          title: AppTexts.category,
                          value: event.category!.name,
                          iconColor: getCategoryColor(),
                        ),

                      _DetailCard(
                        icon: event.isPrivate == 1 ? Icons.lock : Icons.public,
                        title: AppTexts.privacy,
                        value: event.isPrivate == 1 ? 'Private' : 'Public',
                        iconColor: event.isPrivate == 1
                            ? Colors.red
                            : Colors.green,
                      ),

                      const SizedBox(height: 16),
                      Text(
                        AppTexts.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (event.members.isNotEmpty) ...[
                        Text(
                          "${AppTexts.participants} (${event.members.length})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: event.members
                              .map(
                                (m) => CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    m.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? valueWidget;

  final Color iconColor;

  const _DetailCard({
    required this.icon,
    required this.title,
    this.value,
    this.valueWidget,
    required this.iconColor,
  }) : assert(
         value != null || valueWidget != null,
         'Either value or valueWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeHelper.greyprimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  valueWidget ??
                      Text(
                        value!,
                        style: TextStyle(
                          color: AppThemeHelper.whiteBlack(context),
                          fontSize: 14,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatEventDateTime(DateTime date, {bool showTime = false}) {
  final type = DateLocalizationHelper.userCalendar.value;
  final display = DateLocalizationHelper.display(date);
  String text;

  switch (type) {
    case 'hijri':
      text = "${display.hDay} - ${display.hMonth}";
      break;
    case 'both':
    case 'gregorian':
    default:
      text =
          "${date.day.toString().padLeft(2, '0')} - "
          "${date.month.toString().padLeft(2, '0')} ";
      break;
  }

  if (showTime) {
    final time =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    text = "$text  $time";
  }

  return text;
}
