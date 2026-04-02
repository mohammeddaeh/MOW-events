import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/category/presentation/widget/show_category_dialog.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';

class AddEventScreen extends GetView<AddEventController> {
  const AddEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.addAnEvent)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventBasicInfoSection(),
            const SizedBox(height: 16),
            _AdminTypeSection(),
            _AttendanceSection(),
            _ManagerVisibilitySection(),
            const SizedBox(height: 16),
            _CategorySection(),
            const SizedBox(height: 16),
            _DateTimeSection(),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _MembersSection(),
            const SizedBox(height: 24),
            _SubmitButton(),
          ],
        ),
      ),
    );
  }
}

class _EventBasicInfoSection extends GetView<AddEventController> {
  const _EventBasicInfoSection();

  @override
  Widget build(BuildContext context) {
    final borderColor = AppThemeHelper.border(context);
    final errorColor = AppThemeHelper.red(context);
    final labelColor = AppThemeHelper.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final error = controller.nameError.value;
          return TextField(
            controller: controller.nameController,
            onChanged: (_) => controller.nameError.value = null,
            decoration: InputDecoration(
              labelText: AppTexts.eventName,
              labelStyle: TextStyle(color: labelColor),
              errorText: error,
              errorStyle: TextStyle(color: errorColor, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: error != null ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: errorColor, width: 1.5),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.whiteBlack(context),
            ),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          final error = controller.locationError.value;
          return TextField(
            controller: controller.locationController,
            onChanged: (_) => controller.locationError.value = null,
            decoration: InputDecoration(
              labelText: AppTexts.addresse,
              labelStyle: TextStyle(color: labelColor),
              errorText: error,
              errorStyle: TextStyle(color: errorColor, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: error != null ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: errorColor, width: 1.5),
              ),
            ),
            style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          final error = controller.descriptionError.value;
          return TextField(
            controller: controller.descriptionController,
            onChanged: (_) => controller.descriptionError.value = null,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppTexts.description,
              labelStyle: TextStyle(color: labelColor),
              errorText: error,
              errorStyle: TextStyle(color: errorColor, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: error != null ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null ? errorColor : borderColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: errorColor, width: 1.5),
              ),
            ),
            style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
          );
        }),
      ],
    );
  }
}

class _CategorySection extends GetView<AddEventController> {
  const _CategorySection();

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
        visible = controller.adminEventType.value != AdminEventType.private;
      } else {
        visible = controller.visibility.value == EventVisibility.included;
      }

      if (!visible) return const SizedBox.shrink();

      return _CategoryDropdown();
    });
  }
}

class _CategoryDropdown extends GetView<AddEventController> {
  @override
  Widget build(BuildContext context) {
    final categoriesCtrl = controller.categoriesController;
    if (categoriesCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final categories = categoriesCtrl.categories;

      if (categories.isEmpty) {
        return InkWell(
          onTap: () async {
            await showCategoryDialog(controller: categoriesCtrl);

            if (categories.isNotEmpty) {
              controller.selectedCategoryId.value = categories.last.id;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  AppTexts.addCategory,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return DropdownButtonFormField<int>(
        value: controller.selectedCategoryId.value,
        decoration: InputDecoration(
          labelText: AppTexts.chooseCategory,
          border: OutlineInputBorder(),
        ),
        items: categories
            .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (v) => controller.selectedCategoryId.value = v,
      );
    });
  }
}

class _AdminTypeSection extends GetView<AddEventController> {
  const _AdminTypeSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showAdminType) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTexts.typeOfEvent,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AdminEventType.values.map((type) {
              final label = {
                AdminEventType.private: AppTexts.private,
                AdminEventType.public: AppTexts.general,
                AdminEventType.included: AppTexts.embedding,
              }[type]!;
              final bool isSelected = controller.adminEventType.value == type;

              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppThemeHelper.whiteWhite(context)
                        : AppThemeHelper.whiteBlack(context),
                  ),
                ),
                selected: controller.adminEventType.value == type,
                onSelected: (_) => controller.adminEventType.value = type,
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class _DateTimeSection extends GetView<AddEventController> {
  const _DateTimeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppDatePicker(
                label: AppTexts.startDate,
                initialValue: controller.selectedStartDate.value,
                onDatePicked: (picked) {
                  controller.selectedStartDate.value = picked;
                  controller.startDateController.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                },
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: AdaptiveFormField(
                controller: controller.startTimeController,
                type: AdaptiveFieldType.time,
                label: AppTexts.startTime,
                onTimeSelected: (t) => controller.selectedStartTime.value = t,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppDatePicker(
                label: AppTexts.endDate,
                initialValue: controller.selectedEndDate.value,
                onDatePicked: (picked) {
                  controller.selectedEndDate.value = picked;
                  controller.endDateController.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                },
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: AdaptiveFormField(
                controller: controller.endTimeController,
                type: AdaptiveFieldType.time,
                label: AppTexts.endTime,
                onTimeSelected: (t) => controller.selectedEndTime.value = t,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManagerVisibilitySection extends GetView<AddEventController> {
  const _ManagerVisibilitySection();

  @override
  Widget build(BuildContext context) {
    if (controller.currentUser.department?.isManager != true) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      return SwitchListTile(
        title: Text(AppTexts.publicEvent),
        value: controller.visibility.value == EventVisibility.included,
        onChanged: (v) {
          controller.visibility.value = v
              ? EventVisibility.included
              : EventVisibility.private;
        },
      );
    });
  }
}

class _AttendanceSection extends GetView<AddEventController> {
  const _AttendanceSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.showAttendance
          ? CheckboxListTile(
              title: Text(AppTexts.iWantToAttend),
              value: controller.userCurrentInMembers.value,
              onChanged: (v) => controller.userCurrentInMembers.value = v!,
            )
          : const SizedBox.shrink();
    });
  }
}

class _MembersSection extends GetView<AddEventController> {
  const _MembersSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.canSelectMembers) {
        return const SizedBox.shrink();
      }

      final grouped = controller.membersGroupedByDepartment;
      if (grouped.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTexts.members,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
          const SizedBox(height: 12),

          ...grouped.entries.map((entry) {
            final deptName = entry.key;
            final users = entry.value;
            return _DepartmentGroup(departmentName: deptName, users: users);
          }),
        ],
      );
    });
  }
}

class _DepartmentGroup extends GetView<AddEventController> {
  final Department departmentName;
  final List<UserEntity> users;

  const _DepartmentGroup({required this.departmentName, required this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => controller.toggleDeptExpanded(departmentName),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: AppThemeHelper.whiteBlack(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Obx(() {
                    if (!controller.canSelectMembers)
                      return const SizedBox.shrink();
                    final allSelected = controller.isDepartmentFullySelected(
                      departmentName,
                    );
                    return Checkbox(
                      value: allSelected,
                      onChanged: (_) =>
                          controller.toggleDepartmentSelection(departmentName),
                    );
                  }),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            departmentName.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppThemeHelper.whiteBlack(context),
                            ),
                          ),
                        ),
                        Obx(() {
                          final expanded = controller
                              .deptExpandedRx(departmentName)
                              .value;
                          return Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Users list (visible only when expanded)
        Obx(() {
          final expanded = controller.deptExpandedRx(departmentName).value;
          if (!expanded) return const SizedBox.shrink();

          return Column(
            children: _orderedUsers().map((user) {
              return Obx(() {
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text("${user.firstName} ${user.lastName}"),
                      ),
                      if (_isManagerUser(user))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppTexts.manager,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  value: controller.members.contains(user.id),
                  onChanged: (_) => controller.toggleMember(user.id),
                );
              });
            }).toList(),
          );
        }),
      ],
    );
  }

  List<UserEntity> _orderedUsers() {
    final List<UserEntity> list = List.from(users);
    // Put manager(s) first, then the rest in alphabetical order
    final managers = list
        .where((u) => u.isManager == true || u.department?.isManager == true)
        .toList();
    final others = list
        .where((u) => !(u.isManager == true || u.department?.isManager == true))
        .toList();

    others.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );

    managers.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );

    return [...managers, ...others];
  }

  bool _isManagerUser(UserEntity user) {
    return user.isManager == true || user.department?.isManager == true;
  }
}

class _SubmitButton extends GetView<AddEventController> {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.submit,
          child: controller.isLoading.value
              ? const CircularProgressIndicator()
              : Text(AppTexts.saveEvent),
        ),
      );
    });
  }
}
