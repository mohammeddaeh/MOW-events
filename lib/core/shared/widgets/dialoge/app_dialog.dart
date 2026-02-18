import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

Future<void> showAppDialog({
  required BuildContext context,
  required AppDialogType type,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog(
    context: context,
    builder: (_) =>
        AppDialog(type: type, onConfirm: onConfirm, onCancel: onCancel),
  );
}

class AppDialog extends StatelessWidget {
  final AppDialogType type;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String? extraDescription; // نص إضافي اختياري

  const AppDialog({
    super.key,
    required this.type,
    required this.onConfirm,
    this.onCancel,
    this.extraDescription,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (type.barrierDismissible) {
          onCancel?.call();
          return true; // يسمح بالإغلاق
        }
        return false; // يمنع الإغلاق
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type.lottieAsset != null)
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    type.lottieAsset!,
                    height: 120,

                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(const [
                          '**',
                        ], value: type.lottieColor),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Text(
                type.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                extraDescription ?? type.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onCancel?.call();
                      },
                      child: Text(AppTexts.cancel),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.confirmColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: Text(type.confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
