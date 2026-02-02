import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyStateWidget extends StatelessWidget {
  final String lottieAsset;
  final String title;
  final String? subtitle;
  final double? maxAnimationSize;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    super.key,
    required this.lottieAsset,
    required this.title,
    this.subtitle,
    this.maxAnimationSize,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 🧠 حساب حجم الأنيميشن حسب المساحة
        final availableHeight = constraints.maxHeight;
        final animationSize = (availableHeight * 0.35).clamp(
          120.0,
          maxAnimationSize ?? 240.0,
        );

        return Padding(
          padding: padding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎬 Lottie
                Lottie.asset(
                  lottieAsset,
                  height: animationSize,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                // 📝 العنوان
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
