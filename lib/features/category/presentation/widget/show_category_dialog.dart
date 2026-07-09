import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
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
    Builder(
      builder: (dialogContext) {
        return Obx(() {
          final isDark =
              AppThemeHelper.currentBrightness(dialogContext) ==
              Brightness.dark;
          final borderColor = AppThemeHelper.border(
            dialogContext,
          ).withValues(alpha: 0.8);
          final primary = AppThemeHelper.buttonPrimary(dialogContext);
          final onPrimary = isDark ? AppColors.black : AppColors.white;
          final maxW = math.min(
            420.0,
            MediaQuery.sizeOf(dialogContext).width - 32,
          );

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppThemeHelper.blackWhite(dialogContext),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxW,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEditing
                                ? AppTexts.editCategory
                                : AppTexts.addCategory,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppThemeHelper.whiteBlack(dialogContext),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(result: null),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppThemeHelper.textSecondary(dialogContext),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: _categoryInputDecoration(
                              dialogContext,
                              label: AppTexts.name,
                              icon: Icons.label_outline_rounded,
                              errorText: errors['name'],
                            ),
                            onChanged: (_) => errors['name'] = null,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            minLines: 2,
                            decoration: _categoryInputDecoration(
                              dialogContext,
                              label: AppTexts.description,
                              icon: Icons.notes_rounded,
                              errorText: errors['description'],
                            ),
                            onChanged: (_) => errors['description'] = null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                size: 20,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTexts.chooseColor,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemeHelper.whiteBlack(
                                      dialogContext,
                                    ),
                                  ),
                                ),
                              ),
                              if (errors['color'] != null)
                                Text(
                                  '*',
                                  style: TextStyle(
                                    color: AppThemeHelper.red(dialogContext),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary.withValues(
                                alpha: isDark ? 0.08 : 0.05,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: ColorPickerWidget(
                              selectedColor: color.value,
                              onColorChanged: (c) {
                                color.value = c;
                                errors['color'] = null;
                              },
                            ),
                          ),
                          if (errors['color'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errors['color']!,
                              style: TextStyle(
                                color: AppThemeHelper.red(dialogContext),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading.value
                                ? null
                                : () => Get.back(result: null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppThemeHelper.whiteBlack(
                                dialogContext,
                              ),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppTexts.cancel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primary,
                              foregroundColor: onPrimary,
                              disabledBackgroundColor: primary.withValues(
                                alpha: 0.45,
                              ),
                              disabledForegroundColor: onPrimary.withValues(
                                alpha: 0.6,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isLoading.value
                                ? null
                                : () async {
                                    final hexColor =
                                        '#${color.value.value.toRadixString(16).padLeft(8, '0').substring(2)}';

                                    final validation = controller
                                        .validateCategoryData(
                                          name: nameCtrl.text,
                                          description: descCtrl.text,
                                          colorHex: hexColor,
                                        );
                                    errors.assignAll(
                                      validation.map((k, v) => MapEntry(k, v)),
                                    );
                                    errors['general'] = null;

                                    if (validation.values.any(
                                      (e) => e != null,
                                    )) {
                                      return;
                                    }

                                    final duplicate = controller
                                        .validateDuplicateNameAndColor(
                                          name: nameCtrl.text,
                                          colorHex: hexColor,
                                          excludeId: isEditing
                                              ? category?.id
                                              : null,
                                        );
                                    if (duplicate != null &&
                                        duplicate.isNotEmpty) {
                                      errors['name'] = duplicate['name']?.join(
                                        ' ',
                                      );
                                      errors['color'] = duplicate['color']
                                          ?.join(' ');
                                      errors['general'] = [
                                        if (duplicate['name'] != null)
                                          AppTexts.nameAlreadyTaken,
                                        if (duplicate['color'] != null)
                                          AppTexts.colorAlreadyTaken,
                                      ].join(' / ');
                                      final msg =
                                          errors['general'] ??
                                          AppTexts.somethingWentWrong;
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

                                    final submitResult = isEditing
                                        ? await controller.updateCategory(
                                            newCat,
                                          )
                                        : await controller.addCategory(newCat);

                                    isLoading.value = false;

                                    if (submitResult != null &&
                                        submitResult.isNotEmpty) {
                                      errors['name'] = submitResult['name']
                                          ?.join(' ');
                                      errors['description'] =
                                          submitResult['description']?.join(
                                            ' ',
                                          );
                                      errors['color'] = submitResult['color']
                                          ?.join(' ');
                                      errors['general'] =
                                          submitResult['general']?.join(' ');

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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: onPrimary,
                                    ),
                                  )
                                : Text(
                                    isEditing ? AppTexts.update : AppTexts.add,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ),
    barrierDismissible: true,
  );
  return result;
}

InputDecoration _categoryInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? errorText,
}) {
  final borderColor = AppThemeHelper.border(context);
  final errorColor = AppThemeHelper.red(context);
  final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
  final fill = AppThemeHelper.buttonPrimary(
    context,
  ).withValues(alpha: isDark ? 0.06 : 0.04);

  OutlineInputBorder buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    errorText: errorText,
    errorStyle: TextStyle(color: errorColor, fontSize: 12),
    labelStyle: TextStyle(color: AppThemeHelper.textSecondary(context)),
    prefixIcon: Icon(
      icon,
      size: 20,
      color: AppThemeHelper.buttonPrimary(context),
    ),
    filled: true,
    fillColor: fill,
    border: buildBorder(borderColor),
    enabledBorder: buildBorder(
      errorText != null ? errorColor : borderColor,
      width: errorText != null ? 1.3 : 1,
    ),
    focusedBorder: buildBorder(
      errorText != null
          ? errorColor
          : AppThemeHelper.buttonPrimary(context).withValues(alpha: 0.6),
      width: 1.4,
    ),
    errorBorder: buildBorder(errorColor, width: 1.4),
    focusedErrorBorder: buildBorder(errorColor, width: 1.4),
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
      pickerAreaHeightPercent: 0.32,
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
