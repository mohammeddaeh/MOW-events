import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
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
          children: const [
            _EventBasicInfoSection(),
            SizedBox(height: 16),
            _CategorySection(),
            SizedBox(height: 16),
            _AdminTypeSection(),
            SizedBox(height: 16),
            _DateTimeSection(),
            SizedBox(height: 16),
            _ManagerVisibilitySection(),
            SizedBox(height: 16),
            _AttendanceSection(),
            SizedBox(height: 16),
            _MembersSection(),
            SizedBox(height: 24),
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
    return Column(
      children: [
        TextField(
          controller: controller.nameController,
          decoration: InputDecoration(labelText: AppTexts.eventName),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.locationController,
          decoration: InputDecoration(labelText: AppTexts.addresse),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.descriptionController,
          decoration: InputDecoration(labelText: AppTexts.description),
        ),
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

    // ❌ لا أدمن ولا مدير → لا Obx
    if (!isAdmin && !isManager) {
      return const SizedBox.shrink();
    }

    // ✅ أدمن أو مدير → نستخدم Obx
    return Obx(() {
      bool visible;

      if (isAdmin) {
        visible = controller.adminEventType.value != AdminEventType.private;
      } else {
        // Manager
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
    // إذا ما في categoriesController → لا نعرض شيء
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

            // await showCategoryDialog(controller: categoriesCtrl);

            // if (categories.isNotEmpty) {
            //   controller.selectedCategoryId.value = categories.last.id;
            // }
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            departmentName.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        ...users.map((user) {
          return Obx(() {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text("${user.firstName} ${user.lastName}"),
              value: controller.members.contains(user.id),
              onChanged: (_) => controller.toggleMember(user.id),
            );
          });
        }),
      ],
    );
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
