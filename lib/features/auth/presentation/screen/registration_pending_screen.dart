import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/registration_pending_controller.dart';

class RegistrationPendingScreen extends GetView<RegistrationPendingController> {
  const RegistrationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: AppColors.primary, width: double.infinity),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: SvgPicture.asset(
                      AppImages.logoAndName,
                      height: 100.h,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppThemeHelper.blackWhite(context),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.r),
                        ),
                      ),
                      child: _PendingBody(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (!controller.isCompletingApproval.value) {
                return const SizedBox.shrink();
              }

              return Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 32.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 28.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemeHelper.blackWhite(context),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppThemeHelper.accent(context),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          AppTexts.registrationApprovalProcessing,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppThemeHelper.whiteBlack(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody({required this.controller});

  final RegistrationPendingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.submission.value;
      final user = controller.user.value;
      final isRejected = controller.isRejected;
      final isRefreshing = controller.isRefreshing.value;

      return ListView(
        padding: EdgeInsets.fromLTRB(AppSizes.s24, 24.h, AppSizes.s24, 24.h),
        children: [
          _StatusHero(
            controller: controller,
            isRejected: isRejected,
            isRefreshing: isRefreshing,
          ),
          if (!isRejected) ...[
            SizedBox(height: 12.h),
            _HintCard(
              icon: Icons.notifications_active_outlined,
              color: AppThemeHelper.accent(context),
              message: AppTexts.registrationAwaitingPushHint,
            ),
          ],
          if (isRejected) ...[
            SizedBox(height: 16.h),
            _RejectionCard(
              controller: controller,
              rejectionReason: controller.displayRejectionReason,
            ),
          ],

          SizedBox(height: 18.h),
          Text(
            AppTexts.registrationSubmittedData,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppThemeHelper.textSecondary(context),
            ),
          ),
          SizedBox(height: 10.h),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: AppTexts.fullName,
                value: snapshot != null
                    ? '${snapshot.firstName} ${snapshot.lastName}'.trim()
                    : user?.fullName ?? '',
              ),
              _InfoRow(
                icon: Icons.email_outlined,
                label: AppTexts.email,
                value: snapshot?.email ?? user?.email ?? '',
              ),
              _InfoRow(
                icon: Icons.phone_android_rounded,
                label: AppTexts.phoneNumber,
                value: snapshot?.phone ?? user?.phone ?? '',
              ),
              _InfoRow(
                icon: Icons.apartment_outlined,
                label: AppTexts.section,
                value: snapshot?.departmentName ?? user?.department?.name ?? '',
              ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: AppTexts.accountStatus,
                value: (snapshot?.isManager ?? user?.isManager ?? false)
                    ? AppTexts.registerAsManager
                    : AppTexts.employee,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          if (isRejected) ...[
            _GradientButton(
              label: AppTexts.editRegistrationRequest,
              onPressed: controller.editAndResubmit,
            ),
          ] else ...[
            Text(
              AppTexts.registrationRefreshBackupHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.45,
                color: AppThemeHelper.textSecondary(context),
              ),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: isRefreshing
                  ? null
                  : () => controller.refreshSubmittedData(showErrors: true),
              icon: isRefreshing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppThemeHelper.accent(context),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(AppTexts.refreshStatus),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                side: BorderSide(color: AppThemeHelper.accent(context)),
                foregroundColor: AppThemeHelper.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
          SizedBox(height: 8.h),
          TextButton(
            onPressed: controller.goToLogin,
            child: Text(
              AppTexts.backToLogin,
              style: TextStyle(
                color: AppThemeHelper.accent(context),
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.controller,
    required this.isRejected,
    required this.isRefreshing,
  });

  final RegistrationPendingController controller;
  final bool isRejected;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final color = isRejected
        ? AppThemeHelper.red(context)
        : AppThemeHelper.accent(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected
                      ? AppTexts.registrationRejectedTitle
                      : AppTexts.registrationPendingTitle,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isRejected
                      ? AppTexts.registrationRejectedBadge
                      : AppTexts.registrationPendingBadge,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (!isRejected && isRefreshing)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
            ),
        ],
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({
    required this.controller,
    required this.rejectionReason,
  });

  final RegistrationPendingController controller;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final reason = rejectionReason;
    final red = AppThemeHelper.red(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: red.withValues(alpha: 0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4.w,
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(14.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: red, size: 20),
                        SizedBox(width: 8.w),
                        Text(
                          AppTexts.registrationRejectionReason,
                          style: TextStyle(
                            color: red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      reason?.trim().isNotEmpty == true
                          ? reason!
                          : AppTexts.registrationRejectedDefaultReason,
                      style: TextStyle(
                        color: AppThemeHelper.whiteBlack(context),
                        fontSize: 14.sp,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.45,
                color: AppThemeHelper.whiteBlack(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppThemeHelper.background(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppThemeHelper.border(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppThemeHelper.accent(context)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemeHelper.textSecondary(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onPressed,
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
