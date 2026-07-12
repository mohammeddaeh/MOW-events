import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/orders/presentation/orders_controller.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);
    final primaryColor = AppThemeHelper.buttonPrimary(context);
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTexts.joinRequests,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.orders.isEmpty) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (controller.orders.isEmpty) {
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
                AppTexts.noJoinRequests,
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

        return RefreshIndicator(
          onRefresh: controller.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: controller.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return _OrderCard(order: order, isDark: isDark);
            },
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final UserModel order;
  final bool isDark;

  const _OrderCard({required this.order, required this.isDark});

  Future<void> _onReject(BuildContext context) async {
    if (!InternetGuard.ensureOnline()) return;

    final controller = Get.find<OrdersController>();
    final reasonController = TextEditingController();
    final softRed = AppThemeHelper.red(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.dark : AppColors.backgroundGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppTexts.rejectRequest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.rejectionReason,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppTexts.enterRejectionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppTexts.cancel,
              style: TextStyle(color: AppThemeHelper.whiteBlack(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: softRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Navigator.of(ctx).pop(false);
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(AppTexts.rejectRequest),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.rejectOrder(
        order.id,
        description: reasonController.text.trim(),
      );
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);

    return Obx(() {
      final isProcessing = controller.processingOrderIds.contains(order.id);

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
              blurRadius: isDark ? 12 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            order.fullName.trim().isNotEmpty
                ? order.fullName
                : '${order.firstName} ${order.lastName}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppThemeHelper.whiteBlack(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: order.department?.name.isNotEmpty == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    order.department!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                )
              : null,
          trailing: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: () => _onReject(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppThemeHelper.red(context),
                      tooltip: AppTexts.rejectRequest,
                    ),
                    IconButton(
                      onPressed: () {
                        if (!InternetGuard.ensureOnline()) return;
                        controller.acceptOrder(order.id);
                      },
                      icon: const Icon(Icons.check_rounded),
                      color: AppColors.success,
                      tooltip: AppTexts.acceptRequest,
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
