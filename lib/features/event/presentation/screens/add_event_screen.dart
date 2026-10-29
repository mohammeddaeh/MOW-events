import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/presentation/widget/show_category_dialog.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/member_selection_widgets.dart';
import 'package:mow_events/features/event/presentation/widgets/reminder_dialog_helpers.dart';

/// قيمة وهمية داخل القائمة المنسدلة لفتح «إضافة تصنيف» (معرّفات التصنيفات الحقيقية موجبة).
const int _kDropdownAddCategoryValue = -91001;

/// مساحة إضافية أسفل القائمة عند البحث عن الأعضاء حتى تبقى النتائج فوق الكيبورد.
double _eventFormListBottomPadding(
  BuildContext context,
  EventFormController controller,
) {
  const base = 24.0;
  const searchResultsReserve = 184.0;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final memberSearchFocused = controller.memberSearchFocused.value;
  final memberSearchUx =
      controller.canSelectMembers &&
      (controller.hasMemberSearch || memberSearchFocused);
  return base + keyboard + (memberSearchUx ? searchResultsReserve : 0);
}

class AddEventScreen extends StatelessWidget {
  const AddEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventFormWidget(mode: EventFormMode.create);
  }
}

class EventFormWidget extends StatefulWidget {
  const EventFormWidget({super.key, required this.mode, this.initialEvent});

  final EventFormMode mode;
  final EventModel? initialEvent;

  @override
  State<EventFormWidget> createState() => _EventFormWidgetState();
}

class _EventFormWidgetState extends State<EventFormWidget> {
  late final EventFormController controller;
  late final ScrollController _scrollController;
  Worker? _errorSectionWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<EventFormController>();
    _scrollController = ScrollController();
    _errorSectionWorker = ever<AddEventFormSection?>(
      controller.firstErrorSection,
      (section) {
        if (section == null) return;
        final key = controller.sectionKeys[section];
        final targetContext = key?.currentContext;
        if (targetContext == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _errorSectionWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          widget.mode == EventFormMode.edit
              ? AppTexts.editEvent
              : AppTexts.addAnEvent,
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        final bottom = _eventFormListBottomPadding(context, controller);
        return ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          children: [
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.basicInfo],
              child: const _EventBasicInfoSection(),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.eventType],
              child: const _AdminTypeSection(),
            ),
            const _ManagerVisibilitySection(),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.members],
              child: const MembersSectionWidget(),
            ),
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.category],
              child: const CategorySectionWidget(),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.dateTime],
              child: const _DateTimeSection(),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: controller.sectionKeys[AddEventFormSection.reminders],
              child: const _RemindersSection(),
            ),
            const SizedBox(height: 14),

            SizedBox(height: keyboardInset > 0 ? 8 : 24),
            const _SubmitButton(),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }
}

class _EventBasicInfoSection extends GetView<EventFormController> {
  const _EventBasicInfoSection();

  @override
  Widget build(BuildContext context) {
    final errorColor = AppThemeHelper.red(context);

    return _EventSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventSectionTitle(
            icon: Icons.edit_calendar_rounded,
            title: AppTexts.addAnEvent,
            hasError: controller.hasSectionError(AddEventFormSection.basicInfo),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final error = controller.nameError.value;
            return TextField(
              controller: controller.nameController,
              onChanged: (_) => controller.nameError.value = null,
              decoration: _buildSectionInputDecoration(
                context,
                label: AppTexts.eventName,
                icon: Icons.event_note_rounded,
                errorText: error,
                errorColor: errorColor,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppThemeHelper.whiteBlack(context),
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final error = controller.locationError.value;
            return TextField(
              controller: controller.locationController,
              onChanged: (_) => controller.locationError.value = null,
              decoration: _buildSectionInputDecoration(
                context,
                label: AppTexts.addresse,
                icon: Icons.location_on_outlined,
                errorText: error,
                errorColor: errorColor,
              ),
              style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final error = controller.descriptionError.value;
            return TextField(
              controller: controller.descriptionController,
              onChanged: (_) => controller.descriptionError.value = null,
              maxLines: 4,
              decoration: _buildSectionInputDecoration(
                context,
                label: AppTexts.description,
                icon: Icons.notes_rounded,
                errorText: error,
                errorColor: errorColor,
                alignLabelWithHint: true,
              ),
              style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
            );
          }),
        ],
      ),
    );
  }
}

class CategorySectionWidget extends GetView<EventFormController> {
  const CategorySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = controller.currentUser.isAdmin;
    final isManager = controller.currentUser.department?.isManager == true;

    if (!isAdmin && !isManager) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      bool visible;

      if (isAdmin) {
        visible = controller.adminEventType.value != AdminEventType.personal;
      } else {
        visible = controller.visibility.value == EventVisibility.included;
      }

      if (!visible) return const SizedBox.shrink();

      return const _CategoryDropdown();
    });
  }
}

class _CategoryDropdown extends GetView<EventFormController> {
  const _CategoryDropdown();

  @override
  Widget build(BuildContext context) {
    final categoriesCtrl = controller.categoriesController;
    if (categoriesCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final categories = categoriesCtrl.categories;
      final selectedId = controller.selectedCategoryId.value;
      final hasSelectedInList =
          selectedId != null &&
          categories.any((category) => category.id == selectedId);
      final fallbackCategoryName = controller.editingCategoryName;

      return _EventSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventSectionTitle(
              icon: Icons.category_rounded,
              title: AppTexts.category,
              hasError: controller.hasSectionError(
                AddEventFormSection.category,
              ),
            ),
            const SizedBox(height: 14),
            if (categories.isEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await showCategoryDialog(controller: categoriesCtrl);
                    final list = categoriesCtrl.categories;
                    if (list.isNotEmpty) {
                      controller.selectedCategoryId.value = list.last.id;
                    }
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppThemeHelper.red(context).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeHelper.red(context).withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppThemeHelper.red(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppTexts.addCategory,
                          style: TextStyle(
                            color: AppThemeHelper.red(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: selectedId,
                decoration: _buildSectionInputDecoration(
                  context,
                  label: AppTexts.chooseCategory,
                  icon: Icons.label_outline_rounded,
                  errorText: controller.categoryError.value,
                  errorColor: AppThemeHelper.red(context),
                ),
                items: [
                  if (selectedId != null &&
                      !hasSelectedInList &&
                      fallbackCategoryName != null &&
                      fallbackCategoryName.trim().isNotEmpty)
                    DropdownMenuItem<int>(
                      value: selectedId,
                      child: Text(fallbackCategoryName),
                    ),
                  ...categories.map(
                    (c) =>
                        DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                  ),
                  DropdownMenuItem<int>(
                    value: _kDropdownAddCategoryValue,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppThemeHelper.buttonPrimary(context),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppTexts.addCategory,
                          style: TextStyle(
                            color: AppThemeHelper.buttonPrimary(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  if (v == _kDropdownAddCategoryValue) {
                    await showCategoryDialog(controller: categoriesCtrl);
                    final updated = categoriesCtrl.categories;
                    if (updated.isNotEmpty) {
                      controller.selectedCategoryId.value = updated.last.id;
                    }
                    return;
                  }
                  controller.selectedCategoryId.value = v;
                  controller.categoryError.value = null;
                },
              ),
          ],
        ),
      );
    });
  }
}

class _AdminTypeSection extends GetView<EventFormController> {
  const _AdminTypeSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showAdminType) return const SizedBox.shrink();

      return _EventSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventSectionTitle(
              icon: Icons.tune_rounded,
              title: AppTexts.typeOfEvent,
              hasError: controller.hasSectionError(
                AddEventFormSection.eventType,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AdminEventType.values.map((type) {
                final label = {
                  AdminEventType.personal: AppTexts.personal,
                  AdminEventType.public: AppTexts.general,
                  AdminEventType.included: AppTexts.embedding,
                }[type]!;
                final isSelected = controller.adminEventType.value == type;

                return _EventTypeOptionChip(
                  key: ValueKey(type),
                  label: label,
                  isSelected: isSelected,
                  onTap: () => controller.adminEventType.value = type,
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}

/// زر نوع الحدث: لون أساسي التطبيق عند الاختيار، انتقال لوني، وميض لمس (splash).
class _EventTypeOptionChip extends StatelessWidget {
  const _EventTypeOptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final surface = AppThemeHelper.blackWhite(context);
    final borderIdle = AppThemeHelper.border(context).withOpacity(0.75);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? primary : surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary : borderIdle,
          width: isSelected ? 2.2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: primary.withOpacity(0.45),
          highlightColor: primary.withOpacity(0.22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppThemeHelper.whiteWhite(context)
                    : AppThemeHelper.whiteBlack(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeSection extends GetView<EventFormController> {
  const _DateTimeSection();

  @override
  Widget build(BuildContext context) {
    return _EventSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventSectionTitle(
            icon: Icons.schedule_rounded,
            title: AppTexts.timeAndDate,
            hasError: controller.hasSectionError(AddEventFormSection.dateTime),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;
              Widget buildRow({required Widget first, required Widget second}) {
                if (isCompact) {
                  return Column(
                    children: [first, const SizedBox(height: 12), second],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: first),
                    const SizedBox(width: 12),
                    Expanded(child: second),
                  ],
                );
              }

              return Column(
                children: [
                  buildRow(
                    first: AppDatePicker(
                      label: AppTexts.startDate,
                      initialValue: controller.selectedStartDate.value,
                      onDatePicked: (picked) {
                        controller.selectedStartDate.value = picked;
                        controller.dateTimeError.value = null;
                        controller.startDateController.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      },
                    ),
                    second: AdaptiveFormField(
                      controller: controller.startTimeController,
                      type: AdaptiveFieldType.time,
                      label: AppTexts.startTime,
                      initialTime: controller.selectedStartTime.value,
                      onTimeSelected: (t) {
                        controller.selectedStartTime.value = t;
                        controller.dateTimeError.value = null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  buildRow(
                    first: AppDatePicker(
                      label: AppTexts.endDate,
                      initialValue: controller.selectedEndDate.value,
                      onDatePicked: (picked) {
                        controller.selectedEndDate.value = picked;
                        controller.dateTimeError.value = null;
                        controller.endDateController.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      },
                    ),
                    second: AdaptiveFormField(
                      controller: controller.endTimeController,
                      type: AdaptiveFieldType.time,
                      label: AppTexts.endTime,
                      initialTime: controller.selectedEndTime.value,
                      onTimeSelected: (t) {
                        controller.selectedEndTime.value = t;
                        controller.dateTimeError.value = null;
                      },
                    ),
                  ),
                  Obx(() {
                    final error = controller.dateTimeError.value;
                    if (error == null || error.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          error,
                          style: TextStyle(
                            color: AppThemeHelper.red(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ManagerVisibilitySection extends GetView<EventFormController> {
  const _ManagerVisibilitySection();

  @override
  Widget build(BuildContext context) {
    if (controller.currentUser.department?.isManager != true) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _EventSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventSectionTitle(
                icon: Icons.tune_rounded,
                title: AppTexts.typeOfEvent,
                hasError: controller.hasSectionError(
                  AddEventFormSection.eventType,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [EventVisibility.personal, EventVisibility.included]
                    .map((type) {
                      final label = type == EventVisibility.personal
                          ? AppTexts.personal
                          : AppTexts.embedding;
                      final isSelected = controller.visibility.value == type;
                      return _EventTypeOptionChip(
                        key: ValueKey(type),
                        label: label,
                        isSelected: isSelected,
                        onTap: () => controller.visibility.value = type,
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _RemindersSection extends GetView<EventFormController> {
  const _RemindersSection();

  @override
  Widget build(BuildContext context) {
    if (!controller.canManageEventReminders) return const SizedBox.shrink();

    return Obx(() {
      final reminders = controller.reminders.toList()
        ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
      return _EventSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventSectionTitle(
              icon: Icons.alarm_rounded,
              title: AppTexts.reminders,
              hasError: controller.hasSectionError(
                AddEventFormSection.reminders,
              ),
            ),
            const SizedBox(height: 12),
            if (reminders.isEmpty)
              Text(
                AppTexts.noReminder,
                style: TextStyle(color: AppThemeHelper.textSecondary(context)),
              )
            else
              ...reminders.map((r) {
                // الوقت محسوب من موعد البداية الحالي في الفورم — يتحدث فوراً عند تغييره
                final time = controller.reminderTimeFor(r);
                final isPast = controller.isReminderInPast(r);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatReminderDisplayLabel(r.type, r.value),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppThemeHelper.whiteBlack(context),
                              ),
                            ),
                            if (time != null)
                              Text(
                                isPast
                                    ? '${DateLocalizationHelper.formatCompactDateTime(time)} • ${AppTexts.reminderTimePassedShort}'
                                    : DateLocalizationHelper.formatCompactDateTime(
                                        time,
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPast
                                      ? AppThemeHelper.red(context)
                                      : AppThemeHelper.textSecondary(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _openReminderDialog(context, initial: r),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppThemeHelper.buttonPrimary(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.removeReminder(r),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppThemeHelper.red(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (controller.remindersError.value != null) ...[
              const SizedBox(height: 4),
              Text(
                controller.remindersError.value!,
                style: TextStyle(
                  color: AppThemeHelper.red(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openReminderDialog(context),
                icon: const Icon(Icons.add_alarm_rounded),
                label: Text(AppTexts.addReminder),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openReminderDialog(BuildContext context, {ReminderEntity? initial}) {
    ReminderType type = initial?.type ?? ReminderType.minute;
    final valueController = TextEditingController(
      text: initial?.value.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final reminderColor = AppThemeHelper.buttonPrimary(context);
    String? dialogError;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Theme(
          data: buildReminderDialogTheme(ctx, reminderColor: reminderColor),
          child: AlertDialog(
            title: buildReminderDialogTitle(
              ctx,
              initial == null ? AppTexts.addReminder : AppTexts.editReminder,
              reminderColor: reminderColor,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildReminderTypeDropdown(
                      ctx,
                      value: type,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    buildReminderValueField(
                      ctx,
                      controller: valueController,
                      onChanged: (_) {
                        if (dialogError != null) {
                          setState(() => dialogError = null);
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    buildReminderPreviewCard(
                      ctx,
                      type: type,
                      valueText: valueController.text,
                      reminderColor: reminderColor,
                    ),
                    if (dialogError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          dialogError!,
                          style: TextStyle(
                            color: AppThemeHelper.red(ctx),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppTexts.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final value = int.tryParse(valueController.text.trim());
                  if (value == null) {
                    setState(() => dialogError = AppTexts.invalidNumber);
                    return;
                  }
                  try {
                    if (initial == null) {
                      controller.addReminder(type: type, value: value);
                    } else {
                      controller.updateReminder(
                        original: initial,
                        type: type,
                        value: value,
                      );
                    }
                    Navigator.of(ctx).pop();
                  } catch (e) {
                    setState(() => dialogError = reminderValidationMessage(e));
                  }
                },
                child: Text(initial == null ? AppTexts.add : AppTexts.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MembersSectionWidget extends GetView<EventFormController> {
  const MembersSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showMembersRx.value) {
        return const SizedBox.shrink();
      }

      final allGrouped = controller.membersGroupedByDepartment;
      if (allGrouped.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MemberSectionHeader(
              title: AppTexts.members,
              hasError: controller.hasSectionError(AddEventFormSection.members),
              onShowInfo: () {
                controller.memberSearchFocusNode.unfocus();
                showMemberSearchInfoBottomSheet(context);
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppThemeHelper.blackWhite(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                AppTexts.noMembersAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeHelper.textSecondary(context),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        );
      }
      final grouped = controller.filteredMembersGroupedByDepartment;
      final searchResults = controller.searchResultMembers;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberSectionHeader(
            title: AppTexts.members,
            hasError: controller.hasSectionError(AddEventFormSection.members),
            onShowInfo: () {
              controller.memberSearchFocusNode.unfocus();
              showMemberSearchInfoBottomSheet(context);
            },
          ),
          const SizedBox(height: 12),
          MemberSelectionSearchToolbar(
            controller: controller.memberSearchController,
            focusNode: controller.memberSearchFocusNode,
            hasSearch: controller.hasMemberSearch,
            selectedCount: controller.selectedMembersCount,
            resultCount: searchResults.length,
            searchScopeLabel: controller.memberSearchScopeLabel,
            onChanged: controller.onMemberSearchChanged,
            onClear: controller.clearMemberSearch,
            onFinishSearch: controller.finishMemberSearch,
            onShowSelected: () {
              controller.memberSearchFocusNode.unfocus();
              showSelectedMembersBottomSheet(
                context,
                groupedMembers: controller.selectedMembersGroupedByDepartment,
                onToggleMember: controller.toggleMember,
                isManagerUser: (user) =>
                    user.isManager == true ||
                    user.department?.isManager == true,
              );
            },
          ),
          const SizedBox(height: 12),
          if (controller.hasMemberSearch && searchResults.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppThemeHelper.blackWhite(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                AppTexts.noMembersFoundForSearch,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppThemeHelper.textSecondary(context)),
              ),
            )
          else if (controller.hasMemberSearch)
            MemberSearchResultsCard(
              members: searchResults,
              selectedIds: controller.members.toSet(),
              onToggle: controller.toggleMember,
              isManagerUser: (user) =>
                  user.isManager == true || user.department?.isManager == true,
            )
          else
            CollapsibleItemsList(
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                final deptName = entry.key;
                final users = entry.value;
                return Obx(
                  () => ExpandableDepartmentMembersCard(
                    department: deptName,
                    users: users,
                    isExpanded: controller.deptExpandedRx(deptName).value,
                    allSelected: controller.isDepartmentFullySelected(
                      deptName,
                      useFiltered: controller.hasMemberSearch,
                    ),
                    showUsers:
                        controller.hasMemberSearch ||
                        controller.deptExpandedRx(deptName).value,
                    selectedIds: controller.members.toSet(),
                    onToggleExpanded: () =>
                        controller.toggleDeptExpanded(deptName),
                    onToggleDepartment: () =>
                        controller.toggleDepartmentSelection(
                          deptName,
                          useFiltered: controller.hasMemberSearch,
                        ),
                    onToggleMember: controller.toggleMember,
                    isManagerUser: (user) =>
                        user.isManager == true ||
                        user.department?.isManager == true,
                  ),
                );
              },
            ),
          Obx(() {
            final error = controller.membersError.value;
            if (error == null || error.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  error,
                  style: TextStyle(
                    color: AppThemeHelper.red(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _SubmitButton extends GetView<EventFormController> {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: controller.isLoading.value || !controller.hasChanges
              ? null
              : controller.submit,
          child: controller.isLoading.value
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppThemeHelper.whiteWhite(context),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      controller.submitButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class _EventSectionCard extends StatelessWidget {
  final Widget child;

  const _EventSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          width: w.isFinite ? w : null,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppThemeHelper.blackWhite(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppThemeHelper.border(context).withOpacity(0.55),
            ),
            boxShadow:
                AppThemeHelper.currentBrightness(context) == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
    );
  }
}

class _EventSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool hasError;

  const _EventSectionTitle({
    required this.icon,
    required this.title,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(width: 6),
                Text(
                  '*',
                  style: TextStyle(
                    color: AppThemeHelper.red(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _buildSectionInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? errorText,
  Color? errorColor,
  bool alignLabelWithHint = false,
}) {
  final borderColor = AppThemeHelper.border(context);
  final resolvedErrorColor = errorColor ?? AppThemeHelper.red(context);
  final fill = AppThemeHelper.buttonPrimary(context).withOpacity(
    AppThemeHelper.currentBrightness(context) == Brightness.dark ? 0.06 : 0.04,
  );

  OutlineInputBorder buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    alignLabelWithHint: alignLabelWithHint,
    errorText: errorText,
    errorStyle: TextStyle(color: resolvedErrorColor, fontSize: 12),
    labelStyle: TextStyle(color: AppThemeHelper.textSecondary(context)),
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: fill,
    border: buildBorder(borderColor),
    enabledBorder: buildBorder(
      errorText != null ? resolvedErrorColor : borderColor,
      width: errorText != null ? 1.3 : 1,
    ),
    focusedBorder: buildBorder(
      errorText != null
          ? resolvedErrorColor
          : AppThemeHelper.buttonPrimary(context).withOpacity(0.6),
      width: 1.4,
    ),
    errorBorder: buildBorder(resolvedErrorColor, width: 1.4),
    focusedErrorBorder: buildBorder(resolvedErrorColor, width: 1.4),
  );
}
