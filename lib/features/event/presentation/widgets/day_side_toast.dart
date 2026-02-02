import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class DaySideToast extends StatefulWidget {
  final Widget child;
  final bool fromRight; // true: يظهر من اليمين

  const DaySideToast({super.key, required this.child, this.fromRight = true});

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

    Future.delayed(const Duration(seconds: 3), () {
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
          child: Material(
            elevation: 8,
            color: AppThemeHelper.blackWhite(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppThemeHelper.blackWhite(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
