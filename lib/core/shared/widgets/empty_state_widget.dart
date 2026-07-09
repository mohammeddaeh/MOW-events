import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';

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
    this.padding = const EdgeInsets.all(2),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final animationSize = (availableHeight * 0.35).clamp(
          100.0,
          maxAnimationSize ?? 240.0,
        );

        return Padding(
          padding: padding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  lottieAsset,
                  height: animationSize,
                  fit: BoxFit.contain,
                ),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.h,
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
