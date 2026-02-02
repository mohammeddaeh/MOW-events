// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';

Future<void> showCategoryDialog({
  required CategoriesController controller,
  CategoryModel? category,
  bool isEditing = false,
}) async {
  final nameController = TextEditingController(text: category?.name ?? '');
  final descriptionController = TextEditingController(
    text: category?.description ?? '',
  );
  final color = Rx<Color>(
    category != null ? HexColor.fromHex(category.color) : Colors.blue,
  );

  await Get.dialog(
    AlertDialog(
      title: Text(isEditing ? AppTexts.editCategory : AppTexts.addCategory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppTexts.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: AppTexts.description),
            ),
            const SizedBox(height: 12),
            Obx(
              () => ColorPickerWidget(
                selectedColor: color.value,
                onColorChanged: (c) => color.value = c,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppTexts.cancel)),
        ElevatedButton(
          onPressed: () async {
            if (!InternetGuard.ensureOnline()) {
              // AppSnackBars.errorSnackBar(
              //   title: AppTexts.noInternet,
              //   message: AppTexts.internetRequiredToEditCategory,
              // );
              return;
            }
            final hexColor =
                '#${color.value.value.toRadixString(16).padLeft(8, '0').substring(2)}';
            final newCategory =
                category?.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  color: hexColor,
                ) ??
                CategoryModel(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  color: hexColor,
                );

            if (isEditing && category != null) {
              await controller.updateCategory(newCategory);
            } else {
              await controller.addCategory(newCategory);
            }
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    ),
  );
}

class ColorPickerWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      pickerColor: selectedColor,
      onColorChanged: onColorChanged,
      enableAlpha: false,
      showLabel: true,
      pickerAreaHeightPercent: 0.7,
    );
  }
}

extension HexColor on Color {
  static Color fromHex(String? hexString) {
    if (hexString == null) return Colors.blue;

    final cleaned = hexString.replaceFirst('#', '');

    final isValidHex = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned);
    if (!isValidHex) return Colors.blue;

    return Color(int.parse('ff$cleaned', radix: 16));
  }
}
