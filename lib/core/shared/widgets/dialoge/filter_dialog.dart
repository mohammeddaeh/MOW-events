import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class FilterDialog extends StatefulWidget {
  final HomeController controller;
  final HomeSettings initialSettings;

  const FilterDialog({
    super.key,
    required this.controller,
    required this.initialSettings,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late HomeSettings temp;

  @override
  void initState() {
    super.initState();
    temp = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.controller.allEvents;

    final eventCategories = events
        .map((e) => e.category)
        .whereType<CategoryModel>()
        .fold<Map<int, CategoryModel>>({}, (map, c) {
          map[c.id!] = c;
          return map;
        })
        .values
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppThemeHelper.accent(context);
            }
            return AppThemeHelper.grey(context);
          }),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.sortOptions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemeHelper.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<SortField>(
                      value: temp.sortField,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: SortField.startTime,
                          child: Text(AppTexts.startTime),
                        ),
                        DropdownMenuItem(
                          value: SortField.name,
                          child: Text(AppTexts.name),
                        ),
                        DropdownMenuItem(
                          value: SortField.day,
                          child: Text(AppTexts.day),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => temp = temp.copyWith(sortField: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Row(
                        children: [
                          Radio<SortOrder>(
                            value: SortOrder.asc,
                            groupValue: temp.sortOrder,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(
                              () => temp = temp.copyWith(sortOrder: v),
                            ),
                          ),
                          Text(AppTexts.ascending),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<SortOrder>(
                            value: SortOrder.desc,
                            groupValue: temp.sortOrder,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(
                              () => temp = temp.copyWith(sortOrder: v),
                            ),
                          ),
                          Text(AppTexts.concessive),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              AppTexts.privacyFilter,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemeHelper.border(context)),
              ),
              child: Column(
                children: PrivacyFilter.values.map((p) {
                  return Row(
                    children: [
                      Radio<PrivacyFilter>(
                        value: p,
                        groupValue: temp.privacy,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) =>
                            setState(() => temp = temp.copyWith(privacy: v)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p == PrivacyFilter.all
                            ? AppTexts.all
                            : p == PrivacyFilter.publicOnly
                            ? AppTexts.publicOnly
                            : AppTexts.privateOnly,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              AppTexts.chooseCategory,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemeHelper.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int?>(
                      value: temp.categoryId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(AppTexts.all),
                        ),
                        ...eventCategories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => temp = temp.copyWith(categoryId: v)),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => temp = temp.copyWith(categoryId: null)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemeHelper.accent(context),
                    ),
                    child: Text(AppTexts.reset),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              AppTexts.history,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            AppDatePicker(
              label: AppTexts.from,
              initialValue: temp.startAfter,
              onDatePicked: (date) {
                setState(() => temp = temp.copyWith(startAfter: date));
              },
            ),
            const SizedBox(height: 8),
            AppDatePicker(
              label: AppTexts.to,
              initialValue: temp.endBefore,
              onDatePicked: (date) {
                setState(() => temp = temp.copyWith(endBefore: date));
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.controller.resetSettings();
                    widget.controller.applySettings();
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemeHelper.accent(context),
                  ),
                  child: Text(AppTexts.resetAll),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.controller.settings.value = temp;
                    widget.controller.applySettings();
                    Get.back();
                  },
                  child: Text(AppTexts.oK),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
