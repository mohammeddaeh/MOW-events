import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/general/bindings.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/translation/map_locale.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
import 'package:mow_events/core/utils/theme/app_typography.dart';
import 'package:mow_events/core/utils/theme/app_theme.dart';
import 'package:mow_events/core/utils/theme/theme_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/user_access_guard.dart';

class App extends StatelessWidget {
  const App({super.key});

  static String _initialRoute() {
    try {
      final dr = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      if (dr.isNotEmpty && dr != '/') return dr;
    } catch (_) {}
    return AppRouter.splash;
  }

  @override
  Widget build(BuildContext context) {
    final localeController = Get.put(AppLocaleController(), permanent: true);
    Get.put(ThemeController(), permanent: true);

    return Obx(() {
      DateLocalizationHelper.userCalendar.value;
      DateLocalizationHelper.userTimeFormat.value;

      return GetMaterialApp(
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

        initialRoute: _initialRoute(),
        getPages: AppRouter.appPages,
        routingCallback: (routing) {
          if (Get.isRegistered<UserAccessController>()) {
            Get.find<UserAccessController>().updateCurrentRoute(
              routing?.current,
            );
          }
        },
        builder: (context, child) {
          return DefaultTextStyle(
            style: AppTypography.base(context),
            child: UserAccessGuard(child: child ?? const SizedBox.shrink()),
          );
        },
      );
    });
  }
}
