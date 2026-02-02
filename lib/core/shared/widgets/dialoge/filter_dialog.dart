import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/date_time/app_date_picker.dart';
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTexts.sortOptions,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<SortField>(
                  value: temp.sortField,
                  isExpanded: true,
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
              const SizedBox(width: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Radio<SortOrder>(
                        value: SortOrder.asc,
                        groupValue: temp.sortOrder,
                        onChanged: (v) =>
                            setState(() => temp = temp.copyWith(sortOrder: v)),
                      ),
                      Text(AppTexts.ascending),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<SortOrder>(
                        value: SortOrder.desc,
                        groupValue: temp.sortOrder,
                        onChanged: (v) =>
                            setState(() => temp = temp.copyWith(sortOrder: v)),
                      ),
                      Text(AppTexts.concessive),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(),

          Text(
            AppTexts.privacyFilter,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: PrivacyFilter.values.map((p) {
              return RadioListTile<PrivacyFilter>(
                title: Text(
                  p == PrivacyFilter.all
                      ? AppTexts.all
                      : p == PrivacyFilter.publicOnly
                      ? AppTexts.publicOnly
                      : AppTexts.privateOnly,
                ),
                value: p,
                groupValue: temp.privacy,
                onChanged: (v) =>
                    setState(() => temp = temp.copyWith(privacy: v)),
              );
            }).toList(),
          ),
          const Divider(),

          Text(
            AppTexts.chooseCategory,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButton<int?>(
                  value: temp.categoryId,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: null, child: Text(AppTexts.all)),
                    ...eventCategories.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => temp = temp.copyWith(categoryId: v)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () =>
                    setState(() => temp = temp.copyWith(categoryId: null)),
                child: Text(AppTexts.reset),
              ),
            ],
          ),
          const Divider(),

          Text(AppTexts.history, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),

          AppDatePicker(
            label: AppTexts.from,
            initialValue: temp.startAfter,
            onDatePicked: (date) {
              setState(() => temp = temp.copyWith(startAfter: date));
            },
          ),
          SizedBox(height: 8),
          AppDatePicker(
            label: AppTexts.to,
            initialValue: temp.endBefore,
            onDatePicked: (date) {
              setState(() => temp = temp.copyWith(endBefore: date));
            },
          ),

          const SizedBox(height: 16),

          // const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.controller.resetSettings();
                  widget.controller.applySettings();
                  Get.back();
                },
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
    );
  }
}
