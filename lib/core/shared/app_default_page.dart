import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/helper_functions.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class AppDefaultPage extends StatelessWidget {
  AppDefaultPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
    this.showActionButton,
    this.fullScreen = true,
    this.onPressedActionButton,
    String? actionButtonText,
  }) : actionButtonText = actionButtonText ?? AppTexts.click;

  final String image;
  final String title, subTitle;
  final bool? showActionButton, fullScreen;
  final String actionButtonText;
  final VoidCallback? onPressedActionButton;

  @override
  Widget build(BuildContext context) {
    final width = fullScreen!
        ? AppHelper.screenWidth * 0.8
        : AppHelper.screenWidth * 0.4;
    final height = fullScreen!
        ? AppHelper.screenHeight * 0.6
        : AppHelper.screenHeight * 0.3;

    return Padding(
      padding: EdgeInsets.all(AppSizes.s24),
      child: Column(
        children: [
          image.endsWith('.svg')
              ? SvgPicture.asset(image, width: width, height: height)
              : Image(image: AssetImage(image), width: width, height: height),

          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppSizes.s16),

          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          if (showActionButton == true)
            Column(
              children: [
                SizedBox(height: AppSizes.s32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressedActionButton,
                    child: Text(actionButtonText),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
