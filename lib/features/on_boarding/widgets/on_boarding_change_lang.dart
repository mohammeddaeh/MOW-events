import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';

class OnBoardingChangeLang extends StatelessWidget {
  const OnBoardingChangeLang({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // top: AppDeviceUtils.appBarHeight,
      right: DateLocalizationHelper.isArabic ? AppSizes.s32 : null,
      left: DateLocalizationHelper.isArabic ? null : AppSizes.s32,
      child: TextButton(
        onPressed: () => AppLocaleController.instance.toggleLang(),
        child: Row(children: [Text('${AppTexts.changeLang}  ')]),
      ),
    );
  }
}
