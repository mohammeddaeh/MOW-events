import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';

class GradientText extends StatelessWidget {
  final String title;
  const GradientText({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0XFF029F8F), Color(0XFF002723)],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ).createShader(bounds),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
