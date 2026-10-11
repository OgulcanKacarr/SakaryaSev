

import 'package:flutter/cupertino.dart';

enum AppAssets {
  logo('assets/images/logo.png'),
  background('assets/images/background.png'),
  iconHome('assets/icons/home_icon.png');

  final String path;
  const AppAssets(this.path);

  /// Asset'i Image olarak döndür
  Image get asImage => Image.asset(path);

  /// Asset'in yolunu döndür
  String get pathString => path;
}