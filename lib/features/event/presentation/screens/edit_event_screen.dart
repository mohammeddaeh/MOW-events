import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/category/presentation/widget/show_category_dialog.dart';
import 'package:mow_events/features/event/presentation/controller/edit_event_controller.dart';

class EditEventScreen extends GetView<EditEventController> {
  const EditEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.editEvent), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _EditCategorySection(),
            const SizedBox(height: 16),
            _buildDateTimeCard(context),
            const SizedBox(height: 16),
            _EditMembersSection(),
            const SizedBox(height: 24),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: AppTexts.eventName,
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppTexts.description,
                prefixIcon: Icon(Icons.description),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.locationController,
              decoration: InputDecoration(
                labelText: AppTexts.theSite,
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.timeAndDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppDatePicker(
              label: AppTexts.startDate,
              initialValue: controller.selectedStartDate.value,
              onDatePicked: (date) {
                controller.selectedStartDate.value = date;
              },
            ),

            SizedBox(height: 12),

            AppDatePicker(
              label: AppTexts.endDate,
              initialValue: controller.selectedEndDate.value,
              onDatePicked: (date) {
                controller.selectedEndDate.value = date;
              },
            ),

            const Divider(height: 32),
            AdaptiveFormField(
              controller: controller.startTimeController,
              type: AdaptiveFieldType.time,
              label: AppTexts.startTime,
              onTimeSelected: (t) => controller.selectedStartTime.value = t,
            ),

            const SizedBox(height: 16),

            AdaptiveFormField(
              controller: controller.endTimeController,
              type: AdaptiveFieldType.time,
              label: AppTexts.endTime,
              onTimeSelected: (t) => controller.selectedEndTime.value = t,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Obx(
      () => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.updateEvent,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(AppTexts.updateEvent),
        ),
      ),
    );
  }
}

class _EditCategorySection extends GetView<EditEventController> {
  const _EditCategorySection();

  @override
  Widget build(BuildContext context) {
    if (!controller.showCategorySection) return const SizedBox.shrink();

    final categoriesCtrl = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>()
        : null;
    if (categoriesCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final categories = categoriesCtrl.categories;
      if (categories.isEmpty) {
        return InkWell(
          onTap: () async {
            await showCategoryDialog(controller: categoriesCtrl);
            if (categoriesCtrl.categories.isNotEmpty) {
              controller.selectedCategoryId.value =
                  categoriesCtrl.categories.last.id;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline),
                const SizedBox(width: 8),
                Text(AppTexts.addCategory),
              ],
            ),
          ),
        );
      }

      return DropdownButtonFormField<int>(
        value: controller.selectedCategoryId.value,
        decoration: InputDecoration(
          labelText: AppTexts.category,
          border: const OutlineInputBorder(),
        ),
        hint: Text(AppTexts.selectCategory),
        items: categories
            .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (v) => controller.selectedCategoryId.value = v,
      );
    });
  }
}

class _EditMembersSection extends GetView<EditEventController> {
  const _EditMembersSection();

  @override
  Widget build(BuildContext context) {
    // عرض قسم الأعضاء فقط للأحداث المضمنة (included) - ليس للأحداث الخاصة
    if (!controller.showMembersSection) return const SizedBox.shrink();

    return Obx(() {
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
          ...grouped.entries.map(
            (entry) =>
                _EditDeptGroup(departmentName: entry.key, users: entry.value),
          ),
        ],
      );
    });
  }
}

class _EditDeptGroup extends GetView<EditEventController> {
  final Department departmentName;
  final List<UserEntity> users;

  const _EditDeptGroup({required this.departmentName, required this.users});

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
        Obx(() {
          final expanded = controller.deptExpandedRx(departmentName).value;
          if (!expanded) return const SizedBox.shrink();
          return Column(
            children: _orderedUsers()
                .map(
                  (user) => Obx(
                    () => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text('${user.firstName} ${user.lastName}'),
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
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      value: controller.members.contains(user.id),
                      onChanged: (_) => controller.toggleMember(user.id),
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  List<UserEntity> _orderedUsers() {
    final list = List<UserEntity>.from(users);
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

  bool _isManagerUser(UserEntity user) =>
      user.isManager == true || user.department?.isManager == true;
}
