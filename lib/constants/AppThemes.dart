import 'package:flutter/material.dart';
import 'AppColors.dart';

class AppThemes {


  //light
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      brightness: Brightness.light,

      //nesneler
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPrimary,
        titleTextStyle: TextStyle(color: AppColors.lightText, fontSize: 18),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightText),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.lightPrimary,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }

  //dark
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      brightness: Brightness.dark,

      //nesneler
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkPrimary,
        titleTextStyle: TextStyle(color: AppColors.darkText, fontSize: 18),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkText),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.darkPrimary,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}