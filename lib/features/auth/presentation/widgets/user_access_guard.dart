import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';

class UserAccessGuard extends GetView<UserAccessController> {
  final Widget child;

  const UserAccessGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final shouldBlock =
          controller.shouldBlockProtectedRoutes &&
          controller.isOnProtectedRoute;

      final overlayColor = AppThemeHelper.blackBblack(
        context,
      ).withValues(alpha: 0.55);
      final cardColor = AppThemeHelper.blackWhite(context);
      final iconColor = AppThemeHelper.buttonPrimary(context);
      final titleColor = AppThemeHelper.whiteBlack(context);
      final descriptionColor = AppThemeHelper.textSecondary(context);

      return PopScope(
        canPop: !shouldBlock,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (shouldBlock) ...[
              ModalBarrier(dismissible: false, color: overlayColor),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Material(
                      color: cardColor,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.state.value ==
                                        UserAccessState.inactive
                                    ? Icons.block_rounded
                                    : Icons.sync_rounded,
                                color: iconColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              controller.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    height: 1.6,
                                    color: descriptionColor,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.isChecking
                                    ? null
                                    : controller.refreshStatus,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppThemeHelper.buttonPrimary(
                                    context,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: controller.isChecking
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(controller.actionLabel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
