import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';

Future<bool?> showCategoryDialog({
  required CategoriesController controller,
  CategoryModel? category,
  bool isEditing = false,
}) async {
  final nameCtrl = TextEditingController(text: category?.name ?? '');
  final descCtrl = TextEditingController(text: category?.description ?? '');
  final color = Rx<Color>(
    category != null ? HexColor.fromHex(category.color) : Colors.blue,
  );
  final isLoading = false.obs;

  final errors = <String, String?>{
    'general': null,
    'name': null,
    'description': null,
    'color': null,
  }.obs;

  final result = await Get.dialog<bool>(
    Obx(
      () => AlertDialog(
        title: Text(isEditing ? AppTexts.editCategory : AppTexts.addCategory),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: AppTexts.name,
                  errorText: errors['name'],
                ),
                onChanged: (_) => errors['name'] = null,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: AppTexts.description,
                  errorText: errors['description'],
                ),
                onChanged: (_) => errors['description'] = null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text(AppTexts.chooseColor),
                  if (errors['color'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('*', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              ColorPickerWidget(
                selectedColor: color.value,
                onColorChanged: (c) {
                  color.value = c;
                  errors['color'] = null;
                },
              ),
              if (errors['color'] != null)
                Text(
                  errors['color']!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: Text(AppTexts.cancel),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      final hexColor =
                          '#${color.value.value.toRadixString(16).padLeft(8, '0').substring(2)}';

                      final validation = controller.validateCategoryData(
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        colorHex: hexColor,
                      );
                      errors.assignAll(
                        validation.map((k, v) => MapEntry(k, v)),
                      );
                      errors['general'] = null;

                      if (validation.values.any((e) => e != null)) return;

                      final duplicate = controller
                          .validateDuplicateNameAndColor(
                            name: nameCtrl.text,
                            colorHex: hexColor,
                            excludeId: isEditing ? category?.id : null,
                          );
                      if (duplicate != null && duplicate.isNotEmpty) {
                        errors['name'] = duplicate['name']?.join(' ');
                        errors['color'] = duplicate['color']?.join(' ');
                        errors['general'] = [
                          if (duplicate['name'] != null)
                            AppTexts.nameAlreadyTaken,
                          if (duplicate['color'] != null)
                            AppTexts.colorAlreadyTaken,
                        ].join(' / ');
                        final msg =
                            errors['general'] ?? AppTexts.somethingWentWrong;
                        AppSnackBars.errorSnackBar(
                          title: AppTexts.error,
                          message: msg,
                        );
                        return;
                      }

                      isLoading.value = true;
                      final newCat =
                          category?.copyWith(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            color: hexColor,
                          ) ??
                          CategoryModel(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            color: hexColor,
                          );

                      final result = isEditing
                          ? await controller.updateCategory(newCat)
                          : await controller.addCategory(newCat);

                      isLoading.value = false;

                      if (result != null && result.isNotEmpty) {
                        errors['name'] = result['name']?.join(' ');
                        errors['description'] = result['description']?.join(
                          ' ',
                        );
                        errors['color'] = result['color']?.join(' ');
                        errors['general'] = result['general']?.join(' ');

                        final msg =
                            errors['general'] ??
                            errors['name'] ??
                            errors['color'] ??
                            errors['description'] ??
                            AppTexts.failedToAddCategory;
                        AppSnackBars.errorSnackBar(
                          title: AppTexts.error,
                          message: msg,
                        );
                        return;
                      }

                      Get.back(result: true);
                    },
              child: isLoading.value
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? AppTexts.update : AppTexts.add),
            ),
          ),
        ],
      ),
    ),
  );
  return result;
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
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) return Colors.blue;
    return Color(int.parse('ff$cleaned', radix: 16));
  }
}
