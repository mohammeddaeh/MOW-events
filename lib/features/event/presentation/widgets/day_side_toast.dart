import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class DaySideToast extends StatefulWidget {
  final Widget child;
  final bool fromRight;
  final Duration duration;

  const DaySideToast({
    super.key,
    required this.child,
    this.fromRight = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<DaySideToast> createState() => _DaySideToastState();
}

class _DaySideToastState extends State<DaySideToast>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slide;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    slide = Tween<Offset>(
      begin: Offset(widget.fromRight ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) controller.reverse();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.fromRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppThemeHelper.blackWhite(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
