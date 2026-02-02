import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class AppImagePreviewDialog extends StatelessWidget {
  final File image;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppImagePreviewDialog({
    super.key,
    required this.image,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: InteractiveViewer(
              child: Image.file(image, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppTexts.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(AppTexts.acceptance),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
