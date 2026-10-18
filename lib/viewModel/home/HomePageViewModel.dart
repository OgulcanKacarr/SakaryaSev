
import 'package:flutter/material.dart';

class HomePageViewModel extends ChangeNotifier {
  String selectedPage = 'home';
  bool settingsExpanded = true;

  void selectPage(String page) {
    selectedPage = page;
    notifyListeners();
  }

  void toggleSettings() {
    settingsExpanded = !settingsExpanded;
    notifyListeners();
  }
}
