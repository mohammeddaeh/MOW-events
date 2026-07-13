import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/orders/presentation/orders_controller.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: AppThemeHelper.textSecondary(context),
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: [
            Obx(
              () => Tab(
                text:
                    '${AppTexts.statusPending} '
                    '(${controller.pendingOrders.length})',
              ),
            ),
            Obx(
              () => Tab(
                text:
                    '${AppTexts.statusRejected} '
                    '(${controller.rejectedOrders.length})',
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingOrdersTab(controller: controller, isDark: isDark),
          _RejectedOrdersTab(controller: controller),
        ],
      ),
    );
  }
}

class _OfflineState extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);
    final primaryColor = AppThemeHelper.buttonPrimary(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: AppThemeHelper.textSecondary(context),
            ),
            const SizedBox(height: 12),
            Text(
              AppTexts.joinRequestsOfflineTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppThemeHelper.whiteBlack(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppTexts.joinRequestsOfflineDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppThemeHelper.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppTexts.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final iconColor = AppThemeHelper.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshableEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String message;
  final IconData icon;

  const _RefreshableEmptyState({
    required this.onRefresh,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyState(message: message, icon: icon),
            ),
          );
        },
      ),
    );
  }
}

class _PendingOrdersTab extends StatelessWidget {
  final OrdersController controller;
  final bool isDark;

  const _PendingOrdersTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppThemeHelper.buttonPrimary(context);

    return Obx(() {
      if (controller.isOffline && controller.pendingOrders.isEmpty) {
        return _OfflineState(onRetry: controller.fetchOrders);
      }

      if (controller.isLoading.value && controller.pendingOrders.isEmpty) {
        return Center(child: CircularProgressIndicator(color: primaryColor));
      }

      if (controller.pendingOrders.isEmpty) {
        return _RefreshableEmptyState(
          onRefresh: controller.fetchOrders,
          message: AppTexts.noJoinRequests,
          icon: Icons.inbox_outlined,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchOrders,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: controller.pendingOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = controller.pendingOrders[index];
            return _OrderCard(order: order, isDark: isDark);
          },
        ),
      );
    });
  }
}

class _RejectedOrdersTab extends StatelessWidget {
  final OrdersController controller;

  const _RejectedOrdersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppThemeHelper.buttonPrimary(context);

    return Obx(() {
      if (controller.isOffline && controller.rejectedOrders.isEmpty) {
        return _OfflineState(onRetry: controller.fetchOrders);
      }

      if (controller.isLoading.value && controller.rejectedOrders.isEmpty) {
        return Center(child: CircularProgressIndicator(color: primaryColor));
      }

      if (controller.rejectedOrders.isEmpty) {
        return _RefreshableEmptyState(
          onRefresh: controller.fetchOrders,
          message: AppTexts.noRejectedJoinRequests,
          icon: Icons.person_off_outlined,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchOrders,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: controller.rejectedOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = controller.rejectedOrders[index];
            return _RejectedOrderCard(order: order);
          },
        ),
      );
    });
  }
}

class _RejectedOrderCard extends StatelessWidget {
  final UserModel order;

  const _RejectedOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cardColor = AppThemeHelper.blackWhite(context);
    final borderColor = AppThemeHelper.border(context).withValues(alpha: 0.8);
    final redColor = AppThemeHelper.red(context);
    final reason = order.registrationData.displayRejectionReason;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: redColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppTexts.statusRejected,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: redColor,
                  ),
                ),
              ),
            ],
          ),
          if (order.department?.name.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              order.department!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: AppThemeHelper.textSecondary(context),
              ),
            ),
          ],
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: redColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 13,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
            ),
          ],
        ],
      ),
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
