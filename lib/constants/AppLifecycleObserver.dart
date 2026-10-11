import 'package:flutter/material.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onBackground; // Uygulama arka plana geçtiğinde
  final VoidCallback onForeground; // Uygulama tekrar ön plana geldiğinde
  final VoidCallback onInactive; // Uygulama geçici olarak etkileşimsiz olduğunda
  final VoidCallback onDetached; // Uygulama kaynaklardan ayrılmadan önce
  final bool debug; // Debug loglarını etkinleştir

  AppLifecycleObserver({
    required this.onBackground,
    required this.onForeground,
    this.onInactive = _defaultCallback,
    this.onDetached = _defaultCallback,
    this.debug = false,
  });

  static void _defaultCallback() {
    // Varsayılan boş fonksiyon
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (debug) {
      debugPrint('AppLifecycleObserver: $state');
    }

    switch (state) {
      case AppLifecycleState.inactive:
        onInactive();
        break;
      case AppLifecycleState.paused:
        onBackground();
        break;
      case AppLifecycleState.resumed:
        onForeground();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      default:
        if (debug) {
          debugPrint('Unhandled state: $state');
        }
    }
  }
}
