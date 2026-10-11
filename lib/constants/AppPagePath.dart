

import 'package:flutter/cupertino.dart';

enum AppPagePath {
  homePage('homePage'),
  splashPage('splashPage'),
  createPage('createPage'),
  loginPage('loginPage');

  final String path;
  const AppPagePath(this.path);

  /// Asset'i Image olarak döndür
  Image get asPath => Image.asset(path);

  /// Asset'in yolunu döndür
  String get pathString => path;
}