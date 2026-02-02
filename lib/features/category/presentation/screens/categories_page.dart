import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/category/presentation/widget/show_category_dialog.dart';

import '../../../../core/utils/constants/enums/app_dialog_type.dart';

class CategoriesPage extends StatelessWidget {
  final CategoriesController controller = Get.find();

  CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.manageCategories)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.categories.isEmpty) {
          return Center(child: Text(AppTexts.noCategoriesFound));
        }

        return ListView.builder(
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: HexColor.fromHex(cat.color),
                ),
                title: Text(cat.name),
                subtitle: Text(cat.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        showCategoryDialog(
                          category: cat,
                          controller: controller,
                          isEditing: true,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (!InternetGuard.ensureOnline()) {
                          return;
                        }
                        showAppDialog(
                          context: context,
                          type: AppDialogType.delete,

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
        onPressed: () => showCategoryDialog(controller: controller),
        child: Icon(Icons.add),
      ),
    );
  }
}
