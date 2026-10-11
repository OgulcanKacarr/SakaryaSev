import 'package:flutter/cupertino.dart';

class AppSizes {
  // Sabit Padding Değerleri
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Sabit Margin Değerleri
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  // Ekran Boyutları (Responsive Design)
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Responsive Ölçekleme (Referans Genişlik: 375)
  static double scaleWidth(BuildContext context, double size) =>
      size * MediaQuery.of(context).size.width / 375;

  static double scaleHeight(BuildContext context, double size) =>
      size * MediaQuery.of(context).size.height / 812;

  // Responsive Yazı Boyutlandırma
  static double fontSize(BuildContext context, double size) => scaleWidth(context, size);

  // Yaygın Yazı Boyutları
  static double smallFont(BuildContext context) => fontSize(context, 12);
  static double normalFont(BuildContext context) => fontSize(context, 14);
  static double mediumFont(BuildContext context) => fontSize(context, 16);
  static double largeFont(BuildContext context) => fontSize(context, 20);
  static double extraLargeFont(BuildContext context) => fontSize(context, 24);
}
