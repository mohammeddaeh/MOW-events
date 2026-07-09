import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/category/presentation/widget/show_category_dialog.dart';

import '../../../../core/utils/constants/enums/app_dialog_type.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoriesController controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);
    final primaryColor = AppThemeHelper.buttonPrimary(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          AppSnackBars.hideSnackBar();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppTexts.manageCategories,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (controller.categories.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  AppTexts.noCategoriesFound,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppThemeHelper.textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              final categoryColor = HexColor.fromHex(cat.color);

              return Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.14 : 0.06,
                      ),
                      blurRadius: isDark ? 12 : 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  minLeadingWidth: 8,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    width: 14,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppThemeHelper.whiteBlack(context),
                    ),
                  ),
                  subtitle: cat.description.trim().isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            cat.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeHelper.textSecondary(context),
                            ),
                          ),
                        ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: AppTexts.edit,
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppThemeHelper.buttonPrimary(context),
                        ),
                        onPressed: () async {
                          final success = await showCategoryDialog(
                            category: cat,
                            controller: controller,
                            isEditing: true,
                          );
                          if (success == true && context.mounted) {
                            AppSnackBars.successSnackBar(
                              title: AppTexts.success,
                              message: AppTexts.categoryUpdatedSuccessfully,
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: AppTexts.delete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          if (!InternetGuard.ensureOnline()) {
                            return;
                          }
                          showAppDialog(
                            context: context,
                            type: AppDialogType.deleteCategories,
                            onConfirm: () {
                              controller.deleteCategories([cat.id!]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final success = await showCategoryDialog(controller: controller);
            if (success == true && context.mounted) {
              AppSnackBars.successSnackBar(
                title: AppTexts.success,
                message: AppTexts.categoryAddedSuccessfully,
              );
            }
          },
          backgroundColor: AppThemeHelper.buttonPrimary(context),
          foregroundColor: Get.isDarkMode ? Colors.black : Colors.white,
          elevation: 6,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}
