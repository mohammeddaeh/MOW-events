import 'package:flutter/material.dart';

import 'package:mow_events/core/shared/widgets/dialoge/filter_dialog.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class FilterButton extends StatelessWidget {
  final HomeController controller;

  const FilterButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () => HomeFilterDialog.show(context, controller),
    );
  }
}

class HomeFilterDialog {
  static void show(BuildContext context, HomeController controller) {
    final HomeSettings tempSettings = controller.settings.value.copyWith();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppTexts.filteringAndSorting, textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: FilterDialog(
            controller: controller,
            initialSettings: tempSettings,
          ),
        ),
        actions: [],
        scrollable: true,
      ),
    );
  }
}
