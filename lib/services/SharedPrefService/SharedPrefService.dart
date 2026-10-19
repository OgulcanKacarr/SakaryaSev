import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/AppStrings.dart';
import '../../constants/ConstMethods.dart';

class SharedPrefService {

  // String veriyi kaydet
  static Future<void> saveString(BuildContext context, String name, String data) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(name, data);
    ConstMethods.showDialogBox(context: context, title: AppStrings.savedSuccessful, content: AppStrings.save);
  }

  // String veriyi oku
  static Future<String> readString(String name) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? value = sharedPreferences.getString(name);
    return value!;
  }

  // Integer veriyi kaydet
  static Future<void> saveInt(BuildContext context, String name, int data) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setInt(name, data);
    ConstMethods.showDialogBox(context: context, title: AppStrings.savedSuccessful, content: AppStrings.save);
  }

  // Integer veriyi oku
  static Future<int?> readInt(String name) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int? value = sharedPreferences.getInt(name);
    return value;
  }

  // Boolean veriyi kaydet
  static Future<void> saveBool(String name, bool data) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(name, data);
  }

  // Boolean veriyi oku
  static Future<bool> readBool(String name) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool? value = sharedPreferences.getBool(name);
    return value ?? true;
  }
// Varsayılan değeri belirlenebilen Boolean veriyi oku
  static Future<bool> readBoolWithDefault(
      String name, {
        required bool defaultValue,
      }) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(name) ?? defaultValue;
  }
  // Double veriyi kaydet
  static Future<void> saveDouble(BuildContext context, String name, double data) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setDouble(name, data);
    ConstMethods.showDialogBox(context: context, title: AppStrings.savedSuccessful, content: AppStrings.save);
  }

  // Double veriyi oku
  static Future<double?> readDouble(String name) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    double? value = sharedPreferences.getDouble(name);
    return value;
  }

  // List<String> veriyi kaydet
  static Future<void> saveStringList(BuildContext context, String name, List<String> data) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setStringList(name, data);
    ConstMethods.showDialogBox(context: context, title: AppStrings.savedSuccessful, content: AppStrings.save);
  }

  // List<String> veriyi oku
  static Future<List<String>?> readStringList(String name) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String>? value = sharedPreferences.getStringList(name);
    return value;
  }

  // Tüm veriyi sil
  static Future<void> clearAllData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
  }

  static Future<void> saveStringWithoutDialog(
      String name,
      String data,
      ) async {
    SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();

    await sharedPreferences.setString(name, data);
  }
}
