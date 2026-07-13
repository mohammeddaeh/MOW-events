import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mow_events/core/app_update/presentation/app_version_controller.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class AppUpdateGuard extends GetView<AppVersionController> {
  final Widget child;

  const AppUpdateGuard({super.key, required this.child});

  Future<void> _openAppUrl() async {
    final url = controller.appUrl.value;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Obx(() {
          final state = controller.updateState.value;
          final reachedHome = controller.hasReachedHome.value;
          final shouldBlock = reachedHome && state == AppUpdateState.required;
          final shouldShowOptionalDialog =
              reachedHome &&
              state == AppUpdateState.optional &&
              !controller.optionalUpdateDismissed.value;

          if (shouldShowOptionalDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOptionalUpdateDialog();
            });
          }

          if (!shouldBlock) return const SizedBox.shrink();

          final overlayColor = AppThemeHelper.blackBblack(
            context,
          ).withValues(alpha: 0.55);
          final cardColor = AppThemeHelper.blackWhite(context);
          final iconColor = AppThemeHelper.buttonPrimary(context);
          final titleColor = AppThemeHelper.whiteBlack(context);
          final descriptionColor = AppThemeHelper.textSecondary(context);

          return PopScope(
            canPop: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                                  Icons.system_update_rounded,
                                  color: iconColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                AppTexts.updateRequiredTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppTexts.updateRequiredDescription,
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
                                  onPressed: _openAppUrl,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppThemeHelper.buttonPrimary(context),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(AppTexts.updateNow),
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
            ),
          );
        }),
      ],
    );
  }

  void _showOptionalUpdateDialog() {
    if (controller.optionalUpdateDismissed.value) return;
    controller.dismissOptionalUpdate();

    Get.dialog(
      Builder(
        builder: (context) {
          final cardColor = AppThemeHelper.blackWhite(context);
          final iconColor = AppThemeHelper.buttonPrimary(context);
          final titleColor = AppThemeHelper.whiteBlack(context);
          final descriptionColor = AppThemeHelper.textSecondary(context);
          final borderColor = AppThemeHelper.border(context);

          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                      Icons.system_update_rounded,
                      color: iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppTexts.updateAvailableTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppTexts.updateAvailableDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: descriptionColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _openAppUrl();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeHelper.buttonPrimary(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(AppTexts.updateNow),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: descriptionColor,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(AppTexts.later),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
