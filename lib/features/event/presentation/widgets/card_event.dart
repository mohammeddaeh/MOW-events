import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_config.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';
import 'package:mow_events/features/event/presentation/bindings/edit_event_binding.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
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
    final navigator = Navigator.of(context);
    final isInsideAnotherSheet = navigator.canPop();

    if (isInsideAnotherSheet) {
      navigator.pop();
      Future.delayed(const Duration(milliseconds: 200), () {
        final ctx = Get.context;
        if (ctx != null && ctx.mounted) {
          _showRemindersSheet(ctx, event);
        }
      });
    } else {
      _showRemindersSheet(context, event);
    }
  }

  void _showRemindersSheet(BuildContext context, EventModel event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EventRemindersSheet(event: event, now: DateTime.now()),
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

  bool get canEdit {
    final currentUserId = AuthService.currentUser?.id;
    if (event.isPublic == 1) return homeController.isAdmin;
    if (event.isPrivate == 1) {
      return event.userId == null || event.userId == currentUserId;
    }
    if (event.isPublic == 0 && event.isPrivate == 0) {
      if (homeController.isAdmin) return true;
      if (homeController.isManager) {
        return event.userId == null || event.userId == currentUserId;
      }
      return false;
    }
    return false;
  }

  bool get canDelete => canEdit;
  Color getCategoryColor() => CardEvent.categoryColorForEvent(event);

  static Color categoryColorForEvent(EventModel event) {
    if (event.category == null || event.category!.color.isEmpty) {
      return Colors.transparent;
    }
    try {
      return Color(int.parse(event.category!.color.replaceAll('#', '0xff')));
    } catch (e) {
      return AppColors.grey;
    }
  }

  /// يعرض بتوم شيت تفاصيل الحدث (من الإشعارات أو من الكارد). عند الإغلاق يُستدعى [onClosed].
  static Future<void> showEventDetailsSheet(
    BuildContext context,
    EventModel event,
    HomeController homeController, {
    VoidCallback? onClosed,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,

      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
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
                  color: Colors.grey[400],
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
                          iconColor: categoryColorForEvent(event),
                        ),
                      _DetailCard(
                        icon: event.isPrivate == 1 ? Icons.lock : Icons.public,
                        title: AppTexts.privacy,
                        value: event.isPrivate == 1 ? 'Private' : 'Public',
                        iconColor: event.isPrivate == 1
                            ? Colors.red
                            : Colors.green,
                      ),
                      _ParticipantsSection(
                        event: event,
                        homeController: homeController,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    onClosed?.call();
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

            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _EventVisibilityLabel(
                event: event,
                homeController: homeController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullText(BuildContext context) {
    CardEvent.showEventDetailsSheet(context, event, homeController);
  }
}

class _EventVisibilityLabel extends StatelessWidget {
  final EventModel event;
  final HomeController homeController;

  const _EventVisibilityLabel({
    required this.event,
    required this.homeController,
  });

  @override
  Widget build(BuildContext context) {
    if (event.isPublic == 1) {
      return _labelRow(context, Icons.public, AppTexts.general);
    }
    if (event.isPrivate == 1) {
      return _labelRow(context, Icons.lock, AppTexts.private);
    }
    if (event.members.isNotEmpty) {
      return _labelRow(
        context,
        Icons.people_outline,
        '${AppTexts.participants} (${event.members.length})',
      );
    }
    return FutureBuilder<List<int>>(
      future: homeController.eventRepo.getEventMembers(event.id),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return _labelRow(
          context,
          Icons.people_outline,
          '${AppTexts.participants} ($count)',
        );
      },
    );
  }

  Widget _labelRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppThemeHelper.textSecondary(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppThemeHelper.textSecondary(context),
          ),
        ),
      ],
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

/// قسم المشاركون في تفاصيل الحدث — عند الضغط يُفتح بوتوم شيت بقائمة المشاركين (صورة، اسم، قسم)
class _ParticipantsSection extends StatelessWidget {
  final EventModel event;
  final HomeController homeController;

  const _ParticipantsSection({
    required this.event,
    required this.homeController,
  });

  int get _memberCount => event.members.isNotEmpty ? event.members.length : 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _memberCount > 0
          ? Future.value(event.members)
          : homeController.eventRepo.getEventMembers(event.id),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        if (count == 0) return const SizedBox.shrink();

        return InkWell(
          onTap: () => _showParticipantsSheet(context, event, homeController),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 22,
                    color: AppThemeHelper.accent(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppTexts.participants} ($count)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppThemeHelper.whiteBlack(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left,
                    color: AppThemeHelper.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _showParticipantsSheet(
    BuildContext context,
    EventModel event,
    HomeController homeController,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ParticipantsBottomSheet(
        eventId: event.id,
        eventRepo: homeController.eventRepo,
      ),
    );
  }
}

class _ParticipantsBottomSheet extends StatelessWidget {
  final int eventId;
  final EventsRepository eventRepo;

  const _ParticipantsBottomSheet({
    required this.eventId,
    required this.eventRepo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    color: AppThemeHelper.accent(context),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppTexts.participants,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppThemeHelper.whiteBlack(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EventMemberDisplay>>(
                future: eventRepo.getEventMembersWithDetails(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        AppTexts.noEventsThisDay,
                        style: TextStyle(
                          color: AppThemeHelper.textSecondary(context),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = list[index];
                      return _ParticipantTile(member: m);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final EventMemberDisplay member;

  const _ParticipantTile({required this.member});

  /// نص تحت الاسم: "مدير قسم X" أو اسم القسم فقط
  String get _subtitle {
    final dept = member.departmentName?.trim() ?? '';
    if (member.isManager && dept.isNotEmpty) {
      return AppTexts.managerOfDepartment.replaceFirst('%s', dept);
    }
    if (member.isManager) return AppTexts.manager;
    if (dept.isNotEmpty) return dept;
    return '';
  }

  String get _imageUrl {
    final img = member.image;
    if (img == null || img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = img.startsWith('/') ? img : '/$img';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final hasImage = _imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeHelper.whiteBlack(context).withOpacity(0.06)
            : AppThemeHelper.border(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppThemeHelper.border(context),
            child: hasImage
                ? ClipOval(
                    child: Image.network(
                      _imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(context),
                    ),
                  )
                : _avatarFallback(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // الاسم الأول والثاني (سطر واحد مع اختصار إن طال)
                Text(
                  member.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // تحت الاسم: مدير قسم X أو اسم القسم فقط — سطران كحد أقصى للنص الطويل
                if (_subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeHelper.textSecondary(context),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(BuildContext context) {
    final initial = member.name.isNotEmpty
        ? member.name.trim().substring(0, 1).toUpperCase()
        : '?';
    return Text(
      initial,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppThemeHelper.textSecondary(context),
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
