import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/shared/widgets/selectable_link_text.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_config.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_member_display.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';
import 'package:mow_events/features/event/presentation/bindings/edit_event_binding.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';
import 'package:mow_events/features/event/presentation/helpers/event_display_helper.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/event/presentation/screens/edit_event_screen.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_sheet.dart';

class EventCardConfig {
  final bool enableTap;
  final bool showBottomSheet;
  final bool showMembers;
  final bool showPrivacy;
  final bool showCategory;
  final bool showReadMore;

  final bool showMultiDaySpanHint;

  const EventCardConfig({
    this.enableTap = true,
    this.showBottomSheet = true,
    this.showMembers = false,
    this.showPrivacy = false,
    this.showCategory = true,
    this.showReadMore = true,
    this.showMultiDaySpanHint = false,
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
    return start != null ? DateLocalizationHelper.formatTime(start) : '--:--';
  }

  String get endTimeHM {
    final end = endDateTimeSafe;
    return end != null ? DateLocalizationHelper.formatTime(end) : '--:--';
  }

  String get startDateTimeFormatted {
    final start = startDateTimeSafe;
    return start != null
        ? DateLocalizationHelper.formatCompactDateTime(start)
        : '--';
  }

  String get endDateTimeFormatted {
    final end = endDateTimeSafe;
    return end != null
        ? DateLocalizationHelper.formatCompactDateTime(end)
        : '--';
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

  /// هل userId هو منشئ الحدث؟
  /// بعد إضافة created_by من الباك → event.userId يُملأ تلقائياً.
  /// ريثما يُضاف: نستخدم !userCurrentInMembers (المنشئ لا يُضاف كعضو في حدثه).
  static bool _isCreator(EventModel event) {
    final currentUserId = AuthService.currentUser?.id;
    if (currentUserId == null) return false;
    if (event.userId != null) return event.userId == currentUserId;
    return !event.userCurrentInMembers;
  }

  bool get canEdit {
    if (event.isPublic == 1) return homeController.isAdmin;
    if (event.isPrivate == 1)
      return homeController.isAdmin || CardEvent._isCreator(event);
    if (event.isPublic == 0 && event.isPrivate == 0) {
      return homeController.isAdmin ||
          (homeController.isManager && CardEvent._isCreator(event));
    }
    return false;
  }

  bool get canDelete => canEdit;
  Color getCategoryColor() => CardEvent.categoryColorForEvent(event);

  /// منطقة ضغط أزرار الكارد (التذكيرات/الخيارات) — أكبر من الأيقونة نفسها.
  static const Size _cardActionSize = Size(40, 32);

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

  static Color timelineStripeColor(
    BuildContext context,
    EventDayTimeline timeline,
  ) {
    switch (timeline) {
      case EventDayTimeline.ended:
        return AppThemeHelper.textSecondary(context).withValues(alpha: 0.55);
      case EventDayTimeline.upcoming:
        return AppColors.info;
      case EventDayTimeline.ongoing:
        return AppColors.green;
    }
  }

  static Future<void> showEventDetailsSheet(
    BuildContext context,
    EventModel event,
    HomeController homeController, {
    VoidCallback? onClosed,
  }) async {
    final eventNotifier = ValueNotifier<EventModel>(event);
    final capturedMediaQuery = MediaQuery.of(context);

    // تحديث تلقائي للمنشئ/الأدمن عند فتح التفاصيل
    if (homeController.isAdmin || CardEvent._isCreator(event)) {
      Future.microtask(() async {
        if (!InternetGuard.canWrite()) return;
        try {
          final fresh = await homeController.eventRepo.getEventDetails(
            event.id,
          );
          eventNotifier.value = fresh;
          final idx = homeController.allEvents.indexWhere(
            (e) => e.id == fresh.id,
          );
          if (idx >= 0) {
            homeController.allEvents[idx] = fresh;
            homeController.applySettings();
          }
        } catch (_) {}
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaQuery(
        data: capturedMediaQuery,
        child: ValueListenableBuilder<EventModel>(
          valueListenable: eventNotifier,
          builder: (ctx, currentEvent, __) {
            final privacyLabel = _eventPrivacyLabel(currentEvent);
            final isPersonalEvent = _isPersonalEvent(currentEvent);
            return FractionallySizedBox(
              heightFactor: 0.70,
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemeHelper.blackWhite(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppThemeHelper.border(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Category color accent strip
                    if (currentEvent.category != null && !isPersonalEvent)
                      Container(
                        height: 2.5,
                        margin: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                        decoration: BoxDecoration(
                          color: categoryColorForEvent(
                            currentEvent,
                          ).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentEvent.canShowAcceptReject) ...[
                              _InvitationResponseBanner(
                                event: currentEvent,
                                homeController: homeController,
                                onResponded: (updatedEvent) {
                                  eventNotifier.value = updatedEvent;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Event title
                            Text(
                              currentEvent.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppThemeHelper.whiteBlack(context),
                                height: 1.25,
                              ),
                            ),
                            // if (headerLabel.isNotEmpty) ...[
                            //   const SizedBox(height: 5),
                            //   Text(
                            //     headerLabel,
                            //     style: TextStyle(
                            //       fontSize: 13,
                            //       color: AppThemeHelper.textSecondary(context),
                            //     ),
                            //   ),
                            // ],
                            const SizedBox(height: 12),
                            // Chips: category + privacy
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (currentEvent.category != null &&
                                    !isPersonalEvent)
                                  _SheetInfoChip(
                                    icon: Icons.label_rounded,
                                    label: currentEvent.category!.name,
                                    color: categoryColorForEvent(currentEvent),
                                  ),
                                if (privacyLabel.isNotEmpty)
                                  _SheetInfoChip(
                                    icon: isPersonalEvent
                                        ? Icons.lock_outline_rounded
                                        : Icons.public_rounded,
                                    label: privacyLabel,
                                    color: AppThemeHelper.accent(context),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Date/time horizontal block
                            _SheetDateBlock(
                              start: currentEvent.startDateTimeSafe,
                              end: currentEvent.endDateTimeSafe,
                            ),
                            const SizedBox(height: 14),
                            // Location
                            if (currentEvent.location.isNotEmpty) ...[
                              _SheetInfoRow(
                                icon: Icons.location_on_rounded,
                                iconColor: AppThemeHelper.accent(context),
                                label: AppTexts.theSite,
                                value: currentEvent.location,
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Participants
                            _ParticipantsSection(
                              event: currentEvent,
                              homeController: homeController,
                            ),
                            // Description
                            if (currentEvent.description.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                AppTexts.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppThemeHelper.textSecondary(context),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableLinkText(
                                key: ValueKey(
                                  'event_desc_${currentEvent.id}_${currentEvent.description.hashCode}',
                                ),
                                text: currentEvent.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: AppThemeHelper.whiteBlack(context),
                                ),
                                linkStyle: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  fontWeight: FontWeight.w600,
                                  color: AppThemeHelper.buttonPrimary(context),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    onClosed?.call();
  }

  Widget _buildInvitationCard(BuildContext context) {
    final gold = AppColors.gold;
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final name = EventDisplayHelper.displayName(event);
    final startDt = event.startDateTimeSafe;
    final endDt = event.endDateTimeSafe;

    final dateStr = startDt != null
        ? DateLocalizationHelper.formatCompactDateTime(startDt)
        : '';
    final timeStr = (startDt != null && endDt != null)
        ? '${DateLocalizationHelper.formatTime(startDt)} – ${DateLocalizationHelper.formatTime(endDt)}'
        : '';

    return GestureDetector(
      onTap: () => _showFullText(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppThemeHelper.blackWhite(context),
          border: Border.all(
            color: gold.withValues(alpha: isDark ? 0.28 : 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header strip ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: gold.withValues(alpha: isDark ? 0.10 : 0.07),
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 13,
                    color: gold.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppTexts.invitationPending,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: gold.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            // ─── Body ───
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppThemeHelper.whiteBlack(context),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: AppThemeHelper.textSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppThemeHelper.textSecondary(
                                      context,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppThemeHelper.textSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppThemeHelper.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_left,
                    color: AppThemeHelper.textSecondary(context),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (event.canShowAcceptReject) return _buildInvitationCard(context);

    final eventId = event.id.toString();
    final displayName = EventDisplayHelper.displayName(event);
    final displayDescription = EventDisplayHelper.displayDescription(event);
    final cardIssues = EventDisplayHelper.diagnose(event);

    final reminders = ReminderController.to.remindersMap[eventId] ?? [];
    final timelineStripe = CardEvent.timelineStripeColor(
      context,
      EventDayListHelper.classify(event),
    );

    final showRemindersAction = reminders.isNotEmpty;
    final showMenuAction = canEdit || canDelete;
    final actionCount =
        (showRemindersAction ? 1 : 0) + (showMenuAction ? 1 : 0);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRemindersAction)
          Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: () {
                ReminderController.to.openEventReminders(context, event);
              },
              radius: 20,
              child: Tooltip(
                message: AppTexts.reminders,
                child: SizedBox(
                  width: _cardActionSize.width,
                  height: _cardActionSize.height,
                  child: Icon(
                    Icons.alarm_rounded,
                    size: 18,
                    color: AppThemeHelper.buttonPrimary(context),
                  ),
                ),
              ),
            ),
          ),
        if (showMenuAction)
          PopupMenuButton<void>(
            padding: EdgeInsets.zero,
            menuPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ),
            splashRadius: 20,
            child: SizedBox(
              width: _cardActionSize.width,
              height: _cardActionSize.height,
              child: Icon(
                Icons.more_horiz_rounded,
                size: 19,
                color: AppThemeHelper.whiteBlack(context),
              ),
            ),
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
    );

    Widget card = GestureDetector(
      onTap: () => _showFullText(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppThemeHelper.blackWhite(context),
          borderRadius: BorderRadius.circular(12),
          border: BorderDirectional(
            start: BorderSide(color: timelineStripe, width: 3.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemeHelper.whiteBlack(context).withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
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
                            fontSize: 12,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 12,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.startDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.stop, size: 12, color: AppColors.red),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                formatEventDateTime(
                                  event.endDateTimeSafe ?? DateTime.now(),
                                  showTime: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                // مكان محجوز للأزرار — الأزرار نفسها مرسومة فوق الكارد (انظر الـ Stack بالأسفل)
                if (actionCount > 0)
                  SizedBox(
                    width: _cardActionSize.width * actionCount,
                    height: _cardActionSize.height,
                  ),
              ],
            ),
            Row(
              children: [
                if (event.category != null && !_isPersonalEvent(event)) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: getCategoryColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: event.name.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: event.name.trim().isEmpty
                          ? AppThemeHelper.textSecondary(context)
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            if (cardIssues.isNotEmpty) ...[
              const SizedBox(height: 4),
              _EventDayListChip(
                label: cardIssues.length == 1
                    ? EventDisplayHelper.issueLabel(cardIssues.first)
                    : AppTexts.eventCardIncompleteData,
                foreground: AppColors.warning,
                background: AppColors.warning.withValues(alpha: 0.12),
              ),
            ],

            if (config.showMultiDaySpanHint) ...[
              const SizedBox(height: 3),
              _EventDayListChip(
                label: AppTexts.eventSpansMultipleDays,
                foreground: AppThemeHelper.textSecondary(context),
                background: AppThemeHelper.textSecondary(
                  context,
                ).withValues(alpha: 0.14),
              ),
            ],

            const SizedBox(height: 2),

            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    displayDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeHelper.textSecondary(context),
                      fontSize: 13,
                      fontStyle: event.description.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 14, color: AppColors.blue),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _EventVisibilityLabel(
                event: event,
                homeController: homeController,
              ),
            ),
          ],
        ),
      ),
    );

    if (actionCount == 0) return card;

    // زاوية الأزرار منطقة محمية: الضغط حول الأزرار أو تحتها لا يفتح التفاصيل.
    // الحشوة تطابق حشوة الكارد (أعلى 8، جانب 14) حتى تبقى الأزرار بمكانها.
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 16),
              child: actions,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullText(BuildContext context) {
    CardEvent.showEventDetailsSheet(context, event, homeController);
  }
}

class _EventDayListChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _EventDayListChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: foreground,
        ),
      ),
    );
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
      return _labelRow(context, Icons.lock, AppTexts.personal);
    }
    if (event.members.isNotEmpty) {
      return _labelRow(
        context,
        Icons.people_outline,
        '${AppTexts.participants} (${event.members.length})',
      );
    }
    return _labelRow(context, Icons.people_outline, AppTexts.participants);
  }

  Widget _labelRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppThemeHelper.textSecondary(context)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              color: AppThemeHelper.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SheetInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDateBlock extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;

  const _SheetDateBlock({this.start, this.end});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.border(
          context,
        ).withValues(alpha: isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppThemeHelper.border(context).withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SheetDateColumn(
                label: AppTexts.from,
                dateTime: start,
                dotColor: AppColors.green,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1.6,
              color: AppThemeHelper.border(context).withValues(alpha: 0.6),
            ),
            Expanded(
              child: _SheetDateColumn(
                label: AppTexts.to,
                dateTime: end,
                dotColor: AppThemeHelper.red(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDateColumn extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final Color dotColor;

  const _SheetDateColumn({
    required this.label,
    required this.dateTime,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final lines = dateTime != null
        ? DateLocalizationHelper.formatDateLines(dateTime!)
        : const <String>[];
    final timeText = dateTime != null
        ? DateLocalizationHelper.formatTime(dateTime!)
        : '--:--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppThemeHelper.textSecondary(context),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (lines.isEmpty)
            Text(
              '--',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppThemeHelper.whiteBlack(context),
              ),
            )
          else
            ...lines.map(
              (line) => Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppThemeHelper.whiteBlack(context),
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: AppThemeHelper.textSecondary(context),
              ),
              const SizedBox(width: 4),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 13,
                  color: AppThemeHelper.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SheetInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppThemeHelper.textSecondary(context),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemeHelper.whiteBlack(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Banner للدعوة يظهر أعلى تفاصيل الحدث عندما canShowAcceptReject == true
class _InvitationResponseBanner extends StatefulWidget {
  final EventModel event;
  final HomeController homeController;
  final void Function(EventModel) onResponded;

  const _InvitationResponseBanner({
    required this.event,
    required this.homeController,
    required this.onResponded,
  });

  @override
  State<_InvitationResponseBanner> createState() =>
      _InvitationResponseBannerState();
}

class _InvitationResponseBannerState extends State<_InvitationResponseBanner> {
  bool _isLoading = false;

  Future<void> _respond(String status, {String? reason}) async {
    setState(() => _isLoading = true);
    bool willDismiss = false;
    try {
      if (status == 'reject') {
        // الرفض: نُرسل للسيرفر مباشرة — لا نحتاج تفاصيل الحدث بعدها
        await widget.homeController.rejectEventInvitation(
          eventId: widget.event.id,
          descriptionReject: reason,
        );
        if (!mounted) return;
        willDismiss = true;
        Navigator.of(context).pop();
        AppSnackBars.successSnackBar(
          title: AppTexts.success,
          message: AppTexts.eventResponseSentReject,
        );
        // مزامنة مع السيرفر في الخلفية
        widget.homeController.loadEvents(reset: true);
      } else {
        // القبول: نُرسل ونجلب الحدث المحدّث من السيرفر
        final updated = await widget.homeController.changeEventMemberStatus(
          eventId: widget.event.id,
          status: status,
          descriptionReject: reason,
        );
        if (!mounted) return;
        if (updated != null) {
          widget.onResponded(updated);
          final idx = widget.homeController.allEvents.indexWhere(
            (e) => e.id == updated.id,
          );
          if (idx >= 0) {
            widget.homeController.allEvents[idx] = updated;
            widget.homeController.applySettings();
          }
          AppSnackBars.successSnackBar(
            title: AppTexts.success,
            message: AppTexts.eventResponseSentAccept,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBars.errorSnackBar(
          title: AppTexts.error,
          message: AppTexts.anUnexpectedErrorOccurred,
        );
      }
    } finally {
      if (mounted && !willDismiss) setState(() => _isLoading = false);
    }
  }

  Future<void> _onReject() async {
    // منع فتح الديالوغ عند انقطاع الإنترنت — يظهر snackbar تلقائياً
    if (!InternetGuard.ensureOnline()) return;

    final reasonController = TextEditingController();
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final softRed = AppThemeHelper.red(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.dark : AppColors.backgroundGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppTexts.rejectInvitation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.rejectionReason,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppTexts.enterRejectionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppTexts.cancel,
              style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: softRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                AppSnackBars.errorSnackBar(
                  title: AppTexts.alert,
                  message: AppTexts.rejectionReasonRequired,
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(AppTexts.rejectInvitation),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _respond('reject', reason: reasonController.text.trim());
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeHelper.accent(context);
    final softRed = AppThemeHelper.red(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mail_outline_rounded, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppTexts.respondToInvitation,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: AppThemeHelper.border(context)),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          Obx(() {
            final isOnline = NetworkManager.instance.isOnline.value;
            final primary = AppThemeHelper.buttonPrimary(context);
            return Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isOnline ? () => _respond('accept') : null,
                    icon: Icon(
                      isOnline ? Icons.check_rounded : Icons.wifi_off_rounded,
                      size: 18,
                    ),
                    label: Text(AppTexts.acceptInvitation),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withValues(alpha: 0.30),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.45,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isOnline ? _onReject : null,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: softRed.withValues(alpha: isOnline ? 1.0 : 0.35),
                    ),
                    label: Text(
                      AppTexts.rejectInvitation,
                      style: TextStyle(
                        color: softRed.withValues(alpha: isOnline ? 1.0 : 0.35),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: softRed.withValues(
                          alpha: isOnline ? 0.45 : 0.20,
                        ),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  final EventModel event;
  final HomeController homeController;

  const _ParticipantsSection({
    required this.event,
    required this.homeController,
  });

  @override
  Widget build(BuildContext context) {
    // إخفاء قسم الأعضاء للحدث الشخصي إذا كان العضو الوحيد هو المستخدم الحالي
    if (event.isPrivate == 1) {
      final currentUserId = AuthService.currentUser?.id;
      final othersCount = event.members
          .where((id) => id != currentUserId)
          .length;
      if (othersCount == 0) return const SizedBox.shrink();
    }

    if (event.membersDetails.isNotEmpty) {
      return _buildCard(
        context,
        event.membersDetails.length,
        event.membersDetails,
      );
    }
    if (event.members.isNotEmpty) {
      return _buildCard(context, event.members.length, null);
    }
    return const SizedBox.shrink();
  }

  Widget _buildCard(
    BuildContext context,
    int count,
    List<EventMemberDisplay>? details,
  ) {
    final accent = AppThemeHelper.accent(context);
    return InkWell(
      onTap: () => _showParticipantsSheet(context, details),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.18), width: 0.7),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people_outline, size: 15, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${AppTexts.participants} ($count)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_left,
              size: 18,
              color: AppThemeHelper.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsSheet(
    BuildContext context,
    List<EventMemberDisplay>? preloaded,
  ) {
    final capturedMediaQuery = MediaQuery.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MediaQuery(
        data: capturedMediaQuery,
        child: _ParticipantsBottomSheet(
          eventId: event.id,
          eventRepo: homeController.eventRepo,
          preloadedMembers: preloaded,
          showGroupedTabs:
              homeController.isAdmin || CardEvent._isCreator(event),
        ),
      ),
    );
  }
}

class _ParticipantsBottomSheet extends StatelessWidget {
  final int eventId;
  final EventsRepository eventRepo;
  final List<EventMemberDisplay>? preloadedMembers;
  final bool showGroupedTabs;

  const _ParticipantsBottomSheet({
    required this.eventId,
    required this.eventRepo,
    this.preloadedMembers,
    this.showGroupedTabs = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final all = preloadedMembers ?? [];
    final accepted = all.where((m) => m.status == 'accept').toList();
    final pending = all.where((m) => m.status == 'pending').toList();
    final rejected = all.where((m) => m.status == 'reject').toList();

    final accent = AppThemeHelper.accent(context);
    final softRed = AppThemeHelper.red(context);

    final container = Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.blackWhite(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.people_rounded, color: accent, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  '${AppTexts.participants} (${all.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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
          if (showGroupedTabs &&
              (pending.isNotEmpty || rejected.isNotEmpty)) ...[
            // Tab bar — للمنشئ فقط عند وجود معلقين أو مرفوضين
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: AppThemeHelper.textSecondary(context),
              dividerColor: AppThemeHelper.border(context),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _tab(AppTexts.statusAccepted, accepted.length, AppColors.green),
                _tab(AppTexts.statusPending, pending.length, AppColors.warning),
                _tab(AppTexts.statusRejected, rejected.length, softRed),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(context, accepted),
                  _buildList(context, pending),
                  _buildList(context, rejected),
                ],
              ),
            ),
          ] else ...[
            // قائمة بسيطة — للمدعوين
            Expanded(child: _buildList(context, all)),
          ],
        ],
      ),
    );

    if (showGroupedTabs) {
      return DefaultTabController(
        length: 3,
        child: FractionallySizedBox(heightFactor: 0.68, child: container),
      );
    }
    return FractionallySizedBox(heightFactor: 0.55, child: container);
  }

  Tab _tab(String label, int count, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<EventMemberDisplay> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 38,
              color: AppThemeHelper.textSecondary(
                context,
              ).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              AppTexts.noEventsThisDay,
              style: TextStyle(
                color: AppThemeHelper.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _ParticipantTile(member: list[index]),
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
            ? AppThemeHelper.whiteBlack(context).withValues(alpha: 0.06)
            : AppThemeHelper.border(context).withValues(alpha: 0.3),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: member.status),
                  ],
                ),
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
                if (member.status == 'reject' &&
                    member.descriptionReject != null &&
                    member.descriptionReject!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: AppThemeHelper.textSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${AppTexts.rejectionReason}: ${member.descriptionReject}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppThemeHelper.textSecondary(context),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case 'accept':
        color = AppColors.green;
        label = AppTexts.statusAccepted;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'reject':
        color = AppThemeHelper.red(context);
        label = AppTexts.statusRejected;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.warning;
        label = AppTexts.statusPending;
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String formatEventDateTime(DateTime date, {bool showTime = false}) {
  final type = DateLocalizationHelper.userCalendar.value;
  String text;

  switch (type) {
    case 'hijri':
      text =
          '${DateLocalizationHelper.hDay(date)} - ${DateLocalizationHelper.hMonth(date)}';
      break;
    case 'both':
      text = DateLocalizationHelper.formatDateLines(
        date,
        includeYear: false,
        includeCalendarLabelsForBoth: false,
      ).join(' / ');
      break;
    case 'gregorian':
    default:
      text =
          '${DateLocalizationHelper.gDay(date)} - '
          '${DateLocalizationHelper.localizeDigits(date.month.toString().padLeft(2, '0'))}';
      break;
  }

  if (showTime) {
    text = '$text  ${DateLocalizationHelper.formatTime(date)}';
  }

  return text;
}

String _eventPrivacyLabel(EventModel event) {
  if (event.isPrivate == 1) {
    return AppTexts.personal;
  }
  if (event.isPublic == 1) {
    return AppTexts.general;
  }
  return _translatedEventStatus(event.status);
}

bool _isPersonalEvent(EventModel event) {
  if (event.isPrivate == 1) {
    return true;
  }
  final normalized = event.status.trim().toLowerCase();
  return normalized == 'private' || normalized == 'personal';
}

String _translatedEventStatus(String status) {
  final normalized = status.trim().toLowerCase();
  switch (normalized) {
    case 'private':
    case 'personal':
      return AppTexts.personal;
    case 'public':
    case 'general':
      return AppTexts.general;
    default:
      return '';
  }
}
