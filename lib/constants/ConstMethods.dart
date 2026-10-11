import 'package:flutter/material.dart';

class ConstMethods {

  /// Snackbar Gösterimi
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor ?? Colors.black87,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// BottomSheet Gösterimi
  static void showBottomSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  /// CircularProgressIndicator Gösterimi
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Yükleme İptal Etme
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Dialog Gösterimi
  static Future<void> showDialogBox({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = "Tamam",
    VoidCallback? onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
