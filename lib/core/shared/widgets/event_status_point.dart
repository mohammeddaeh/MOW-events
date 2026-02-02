import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';

enum PointType { type1, type2, type3 }

class EventStatusPoint extends StatelessWidget {
  final PointType type;
  final double size;

  const EventStatusPoint({super.key, required this.type, this.size = 10});

  Color getColor() {
    switch (type) {
      case PointType.type1:
        return AppColors.green;
      case PointType.type2:
        return AppColors.purple;
      case PointType.type3:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: getColor(), width: 3.w),
      ),
      child: Center(
        child: Container(
          width: size / 2.w,
          height: size / 2.h,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
