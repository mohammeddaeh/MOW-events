import 'package:flutter/widgets.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;

  static late double screenWidth;
  static late double screenHeight;

  static late double safeAreaHorizontal;
  static late double safeAreaVertical;

  static late double safeWidth;
  static late double safeHeight;

  static const double baseWidth = 375.0;
  static const double baseHeight = 812.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeWidth = screenWidth - safeAreaHorizontal;
    safeHeight = screenHeight - safeAreaVertical;
  }

  static double width(double inputWidth) =>
      (inputWidth / baseWidth) * screenWidth;

  static double height(double inputHeight) =>
      (inputHeight / baseHeight) * screenHeight;

  static double text(double inputFontSize) =>
      (inputFontSize / baseHeight) * screenHeight;

  static double radius(double inputRadius) =>
      (inputRadius / baseWidth) * screenWidth;

  static double icon(double inputSize) => (inputSize / baseWidth) * screenWidth;

  static EdgeInsets paddingAll(double value) => EdgeInsets.all(width(value));

  static EdgeInsets paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) => EdgeInsets.symmetric(
    horizontal: width(horizontal),
    vertical: height(vertical),
  );

  static EdgeInsets paddingOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => EdgeInsets.only(
    left: width(left),
    right: width(right),
    top: height(top),
    bottom: height(bottom),
  );
}

extension SizeExtension on num {
  double get w => SizeConfig.width(toDouble());
  double get h => SizeConfig.height(toDouble());
  double get sp => SizeConfig.text(toDouble());
  double get r => SizeConfig.radius(toDouble());
  double get px => SizeConfig.icon(toDouble());
}

class AppSizes {
  static double s4 = 4.w;
  static double s8 = 8.w;
  static double s12 = 12.w;
  static double s16 = 16.w;
  static double s18 = 18.w;
  static double s20 = 20.w;
  static double s24 = 24.w;
  static double s32 = 32.w;
  static double s56 = 56.w;

  static EdgeInsets paddingSmall = EdgeInsets.all(s8);
  static EdgeInsets paddingMedium = EdgeInsets.all(s16);
  static EdgeInsets paddingLarge = EdgeInsets.all(s24);

  static EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: s16);
  static EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: s16);

  static EdgeInsets paddingAllDefault = EdgeInsets.all(s20);

  static double radiusSmall = 8.r;
  static double radiusMedium = 12.r;
  static double radiusLarge = 20.r;

  static double iconSmall = 16.px;
  static double iconMedium = 24.px;
  static double iconLarge = 32.px;
}
