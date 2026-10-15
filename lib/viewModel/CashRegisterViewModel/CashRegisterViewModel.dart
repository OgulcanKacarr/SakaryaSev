
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/CashItemModel.dart';


final cashRegisterViewModelProvider = ChangeNotifierProvider(
      (ref) => CashRegisterViewModel(),
);

class CashRegisterViewModel extends ChangeNotifier {
  double terminalKasa = 0.0;
  double carsiKasa = 0.0;
  double karasuKasa = 0.0;

  final List<CashItemModel> expenses = [
    CashItemModel(name: "TERMİNAL (POS)", amount: 0, isFixed: true),
    CashItemModel(name: "ÇARŞI (POS)", amount: 0, isFixed: true),
    CashItemModel(name: "ÇARŞI SERVİS", amount: 0, isFixed: true),
    CashItemModel(name: "ÇIKIŞLAR", amount: 0, isFixed: true),
    CashItemModel(name: "AÇIKLAMALI BİLET FARKLARI", amount: 0, isFixed: true),
    CashItemModel(name: "HAMZA Ç.", amount: 1200, isFixed: false),
    CashItemModel(name: "YUSUF Ç.", amount: 1200, isFixed: false),
    CashItemModel(name: "EMİN Ç.", amount: 0, isFixed: false),
    CashItemModel(name: "TALHA Ç.", amount: 0, isFixed: false),
    CashItemModel(name: "KOMUTAN", amount: 1000, isFixed: false),
    CashItemModel(name: "OĞULCAN", amount: 1000, isFixed: false),
  ];

  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  double get totalIncome => terminalKasa + carsiKasa + karasuKasa;
  double get totalExpense => expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get netCash => totalIncome - totalExpense;

  void updateKasa(String type, double val) {
    if (type == 'terminal') terminalKasa = val;
    if (type == 'carsi') carsiKasa = val;
    if (type == 'karasu') karasuKasa = val;
    notifyListeners();
  }

  void updateExpenseAmount(int index, double val) {
    if (index >= 0 && index < expenses.length) {
      expenses[index].amount = val;
      notifyListeners();
    }
  }

  void addExtraExpense(String name, double amount) {
    if (name.trim().isNotEmpty) {
      expenses.add(CashItemModel(
        name: name.trim().toUpperCase(),
        amount: amount,
        isFixed: false,
      ));
      notifyListeners();
    }
  }

  void removeExpense(int index) {
    if (index >= 0 && index < expenses.length && !expenses[index].isFixed) {
      expenses.removeAt(index);
      notifyListeners();
    }
  }

  /// Web ve Masaüstü uyumlu modern PNG Kaydetme / İndirme Fonksiyonu

  Future<String?> saveReportAsPng(GlobalKey repaintKey) async {
    try {
      final boundary =
      repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);

      try {
        final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          return null;
        }

        final pngBytes = byteData.buffer.asUint8List();
        final nowStr =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'Sakaryasev_Kasa_$nowStr.png';

        final userProfile = Platform.environment['USERPROFILE'];

        Directory targetDir = userProfile != null
            ? Directory('$userProfile\\Desktop')
            : await getApplicationDocumentsDirectory();

        if (!await targetDir.exists()) {
          targetDir = await getApplicationDocumentsDirectory();
        }

        final filePath =
            '${targetDir.path}${Platform.pathSeparator}$fileName';

        await File(filePath).writeAsBytes(pngBytes);

        return filePath;
      } finally {
        image.dispose();
      }
    } catch (e) {
      debugPrint('Rapor kaydedilirken hata oluştu: $e');
      return null;
    }
  }

  /// Oluşturulan PNG dosyasını share_plus ile paylaşma / WhatsApp'a gönderme
  Future<void> sharePngFile(String filePath) async {
    if (filePath.isNotEmpty && !filePath.startsWith("Tarayıcı")) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sakaryasev Turizm - Gün Sonu Kasa Raporu',
      );
    } else {
      debugPrint("Web ortamında veya dosya yolunda paylaşılamadı.");
    }
  }

}