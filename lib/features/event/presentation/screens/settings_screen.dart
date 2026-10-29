import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/app_update/presentation/app_version_controller.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
import 'package:mow_events/core/utils/theme/theme_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/event/presentation/widgets/custom_card_setting.dart';
import 'package:mow_events/features/event/presentation/screens/add_reminders_screen.dart';
import 'package:mow_events/features/orders/presentation/orders_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser!.toEntity();
    final localeController = Get.find<AppLocaleController>();
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.user.value;
      final userFullName = '${user?.firstName} ${user?.lastName}';
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  AppTexts.settings,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),

                CustomCardSetting(
                  title: userFullName,
                  subtitle: user == null
                      ? null
                      : AppTexts.userRoleLabel(
                          isManager: user.isManager,
                          department: user.department?.name,
                        ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppThemeHelper.whiteBlack(context),
                      ),
                    ],
                  ),
                  onTap: () => Get.toNamed(AppRouter.profile),
                ),
                if (currentUser.isAdmin == true ||
                    currentUser.department?.isManager == true) ...[
                  CustomCardSetting(
                    title: AppTexts.manageCategories,
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppThemeHelper.whiteBlack(context),
                    ),
                    onTap: () {
                      Get.toNamed(AppRouter.categoriesPage);
                    },
                  ),
                  const _JoinRequestsSettingTile(),
                ],

                const _DateTimeFormatSettingTile(),
                Obx(() {
                  return CustomCardSetting(
                    iconData: Icons.language_outlined,
                    title: AppTexts.language,
                    options: ['ar', 'en'],
                    currentValue: localeController.currentLang.value,
                    onSelected: (val) {
                      localeController.changeLang(val);
                    },
                  );
                }),

                Obx(() {
                  return CustomCardSetting(
                    iconData: themeController.getThemeIcon(
                      themeController.storedTheme.value,
                    ),

                    title: AppTexts.theme,
                    options: const ['light', 'dark', 'system'],
                    currentValue: themeController.storedTheme.value,
                    onSelected: (val) {
                      themeController.changeTheme(val);
                    },
                  );
                }),
                CustomCardSetting(
                  iconData: Icons.alarm,
                  title: AppTexts.alarmReminderSettingsTitle,
                  subtitle: AppTexts.alarmReminderSettingsSubtitle,
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                  onTap: () {
                    Get.to(() => const AddRemindersScreen());
                  },
                ),

                const SizedBox(height: 24),

                OutlinedButton.icon(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: AppColors.errorSecondary,
                    size: 22,
                  ),
                  label: Text(AppTexts.logOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorPrimary,
                    side: BorderSide(
                      color: AppColors.errorSecondary,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    overlayColor: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.08),
                  ),
                  iconAlignment: IconAlignment.start,
                  onPressed: authController.logout,
                ),
                const SizedBox(height: 20),
                const _AppVersionFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _JoinRequestsSettingTile extends StatelessWidget {
  const _JoinRequestsSettingTile();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return Obx(() {
      final hasRequests = controller.pendingOrders.isNotEmpty;

      return CustomCardSetting(
        title: AppTexts.joinRequests,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRequests) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.errorPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ],
        ),
        onTap: () => Get.toNamed(AppRouter.ordersPage),
      );
    });
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  Future<void> _openAppUrl(AppVersionController controller) async {
    final url = controller.appUrl.value;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppVersionController>();

    return Obx(() {
      final hasUpdate = controller.hasOptionalUpdate;
      final version = controller.currentVersion.value;
      final silver = AppThemeHelper.textSecondary(context);
      final accent = AppThemeHelper.buttonPrimary(context);

      return Center(
        child: InkWell(
          onTap: hasUpdate ? () => _openAppUrl(controller) : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUpdate) ...[
                  Icon(
                    Icons.system_update_rounded,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  hasUpdate ? AppTexts.updateAvailableTitle : 'v$version',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasUpdate ? FontWeight.w600 : FontWeight.w500,
                    color: hasUpdate ? accent : silver,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DateTimeFormatSettingTile extends StatelessWidget {
  const _DateTimeFormatSettingTile();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary =
          '${_localizedSettingValue(DateLocalizationHelper.userCalendar.value)} - '
          '${_localizedSettingValue(DateLocalizationHelper.userTimeFormat.value)}';

      return CustomCardSetting(
        iconData: Icons.event_available_outlined,
        title: AppTexts.dateTimeFormatTitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppThemeHelper.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ],
        ),
        onTap: () => _showDateTimeFormatBottomSheet(context),
      );
    });
  }
}

class _FormatBottomSheetOption extends StatelessWidget {
  final String title;
  final String preview;
  final bool selected;
  final VoidCallback onTap;

  const _FormatBottomSheetOption({
    required this.title,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final selectedColor = AppThemeHelper.buttonPrimary(context);
    final selectedTextColor = isDark ? AppColors.black : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor
                : AppThemeHelper.blackWhite(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : AppThemeHelper.border(context).withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? selectedTextColor
                            : AppThemeHelper.whiteBlack(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: selected
                            ? selectedTextColor.withValues(alpha: 0.9)
                            : AppThemeHelper.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: selected
                    ? selectedTextColor
                    : AppThemeHelper.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetFormatSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final String Function(String option) previewBuilder;
  final ValueChanged<String> onSelected;

  const _BottomSheetFormatSection({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.previewBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppThemeHelper.whiteBlack(context),
          ),
        ),
        const SizedBox(height: 10),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FormatBottomSheetOption(
              title: _localizedSettingValue(option),
              preview: previewBuilder(option),
              selected: option == currentValue,
              onTap: () => onSelected(option),
            ),
          );
        }),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeHelper.blackWhite(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeHelper.border(context).withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppThemeHelper.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedSettingValue(String value) {
  return DateLocalizationHelper.localizeDigits(value.tr);
}

Future<void> _showDateTimeFormatBottomSheet(BuildContext context) {
  final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,

    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Obx(() {
        final previewDate = DateTime(2026, 4, 9, 9, 35);
        final dateLines = DateLocalizationHelper.formatDateLines(
          previewDate,
          includeCalendarLabelsForBoth: false,
        );
        final datePreview = DateLocalizationHelper.userCalendar.value == 'both'
            ? dateLines.join(' / ')
            : dateLines.first;
        final timePreview = DateLocalizationHelper.formatTime(previewDate);

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: BoxDecoration(
            color: AppThemeHelper.background(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppThemeHelper.border(sheetContext),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppThemeHelper.buttonPrimary(
                            sheetContext,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.event_available_outlined,
                          color: AppThemeHelper.buttonPrimary(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTexts.dateTimeFormatTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppThemeHelper.whiteBlack(sheetContext),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTexts.dateTimeFormatHint,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppThemeHelper.textSecondary(
                                  sheetContext,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppThemeHelper.buttonPrimary(
                        sheetContext,
                      ).withValues(alpha: isDark ? 0.08 : 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppThemeHelper.buttonPrimary(
                          sheetContext,
                        ).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTexts.formatPreview,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppThemeHelper.buttonPrimary(sheetContext),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PreviewTile(
                                label: AppTexts.dateFormat,
                                value: datePreview,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PreviewTile(
                                label: AppTexts.timeFormat,
                                value: timePreview,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _BottomSheetFormatSection(
                    title: AppTexts.dateFormat,
                    options: const ['gregorian', 'hijri', 'both'],
                    currentValue: DateLocalizationHelper.userCalendar.value,
                    previewBuilder: _dateOptionPreview,
                    onSelected: DateLocalizationHelper.save,
                  ),
                  const SizedBox(height: 18),
                  _BottomSheetFormatSection(
                    title: AppTexts.timeFormat,
                    options: const ['24h', '12h'],
                    currentValue: DateLocalizationHelper.userTimeFormat.value,
                    previewBuilder: _timeOptionPreview,
                    onSelected: DateLocalizationHelper.saveTimeFormat,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

String _dateOptionPreview(String option) {
  final previewDate = DateTime(2026, 4, 9, 21, 35);
  final gregorian =
      '${DateLocalizationHelper.gDay(previewDate)} ${DateLocalizationHelper.gMonth(previewDate)} ${DateLocalizationHelper.gYear(previewDate)} ${AppTexts.m}';
  final hijri =
      '${DateLocalizationHelper.hDay(previewDate)} ${DateLocalizationHelper.hMonth(previewDate)} ${DateLocalizationHelper.hYear(previewDate)} ${AppTexts.h}';

  switch (option) {
    case 'hijri':
      return hijri;
    case 'both':
      return '$gregorian / $hijri';
    case 'gregorian':
    default:
      return gregorian;
  }
}

String _timeOptionPreview(String option) {
  if (option == '12h') {
    return DateLocalizationHelper.formatTimeOfDay(
      const TimeOfDay(hour: 21, minute: 35),
      withPeriod: true,
    );
  }

  return DateLocalizationHelper.localizeDigits('21:35');
}
