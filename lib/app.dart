import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/general/bindings.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/translation/map_locale.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
import 'package:mow_events/core/utils/theme/app_theme.dart';
import 'package:mow_events/core/utils/theme/theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Get.put(AppLocaleController(), permanent: true);
    Get.put(ThemeController(), permanent: true);

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppTexts.appName,

        themeMode: ThemeController.instance.currentThemeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        initialBinding: GeneralBindings(),

        locale: localeController.langCode(localeController.currentLang.value),

        fallbackLocale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        translations: AppLocale(),

        initialRoute: AppRouter.splash,
        getPages: AppRouter.appPages,
      ),
    );
  }
}
