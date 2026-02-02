import 'package:get/get.dart';
import 'package:mow_events/features/auth/presentation/binding/forgot_password_binding.dart';
import 'package:mow_events/features/auth/presentation/binding/log_in_binding.dart';
import 'package:mow_events/features/auth/presentation/binding/profile_binding.dart';
import 'package:mow_events/features/auth/presentation/binding/reset_password_binding.dart';
import 'package:mow_events/features/auth/presentation/binding/verify_code_binding.dart';
import 'package:mow_events/features/auth/presentation/screen/edit_profile_screen.dart';
import 'package:mow_events/features/auth/presentation/screen/forgot_password_screen.dart';
import 'package:mow_events/features/auth/presentation/screen/log_in_screen.dart';
import 'package:mow_events/features/auth/presentation/screen/profile_screen.dart';
import 'package:mow_events/features/auth/presentation/screen/reset_password_screen.dart';
import 'package:mow_events/features/auth/presentation/screen/verify_code_screen.dart';
import 'package:mow_events/features/category/presentation/screens/categories_page.dart';
import 'package:mow_events/features/event/presentation/bindings/add_events_binding.dart';
import 'package:mow_events/features/event/presentation/bindings/edit_event_binding.dart';
import 'package:mow_events/features/event/presentation/bindings/home_binding.dart';
import 'package:mow_events/features/event/presentation/bindings/settings_binding.dart';
import 'package:mow_events/features/event/presentation/screens/add_event_screen.dart';
import 'package:mow_events/features/event/presentation/screens/edit_event_screen.dart';
import 'package:mow_events/features/event/presentation/screens/home_screen.dart';
import 'package:mow_events/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:mow_events/features/event/presentation/screens/settings_screen.dart';
import 'package:mow_events/features/splash/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String logInScreen = '/logInScreen';
  static const String addEventScreen = '/AddEventScreen';
  static const String forgotPassword = '/forgotPassword';
  static const String verifyCode = '/verifyCode';
  static const String resetPassword = '/resetPassword';
  static const String homeScreen = '/homeScreen';
  static const String settings = '/settings';
  static const String editProfile = '/editProfile';
  static const String profile = '/profile';
  static const String editEvent = '/editEvent';
  static const String categoriesPage = '/categoriesPage';
  static const String notifications = '/notifications';

  static List<GetPage> appPages = [
    GetPage(name: splash, page: () => SplashScreen()),

    GetPage(
      name: logInScreen,
      page: () => LogInScreen(),
      binding: LogInBinding(),
    ),

    GetPage(
      name: forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: verifyCode,
      page: () => VerifyCodeScreen(),
      binding: VerifyCodeBinding(),
    ),
    GetPage(
      name: resetPassword,
      page: () => ResetPasswordScreen(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: AppRouter.profile,
      page: () => ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRouter.editProfile,
      page: () => EditProfileScreen(),
      binding: ProfileBinding(),
    ),

    GetPage(name: homeScreen, page: () => HomeScreen(), binding: HomeBinding()),
    GetPage(
      name: settings,
      page: () => SettingsScreen(),
      binding: SettingsBinding(),
    ),

    GetPage(
      name: AppRouter.addEventScreen,
      page: () => AddEventScreen(),
      binding: AddEventBinding(),
    ),
    GetPage(
      name: AppRouter.editEvent,
      page: () => EditEventScreen(),
      binding: EditEventBinding(),
    ),
    GetPage(name: AppRouter.categoriesPage, page: () => CategoriesPage()),
    GetPage(name: AppRouter.notifications, page: () => NotificationsScreen()),
  ];
}
