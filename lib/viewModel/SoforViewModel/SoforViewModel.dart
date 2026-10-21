import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/Sofor/Sofor.dart';
import '../../services/DatabaseService/DatabaseService.dart';

final soforProvider = ChangeNotifierProvider((ref) => SoforViewModel());

class SoforViewModel extends ChangeNotifier {
  List<Sofor> _tumSoforler = [];
  List<Sofor> _filtreliSoforler = [];
  bool _yukleniyor = false;
  String? _hata;
  String _aramaMetni = '';

  List<Sofor> get soforler => _filtreliSoforler;
  int get toplamSofor => _tumSoforler.length;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  SoforViewModel() {
    yukle();
  }

  Future<void> yukle() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      final dbVeriler = DatabaseService.instance.getAllSoforler();
      _tumSoforler = dbVeriler.map((map) => Sofor(
        id: map['id'].toString(),
        ad: map['ad'] as String,
        soyad: map['soyad'] as String,
        telefon: map['telefon'] as String,
        tc: map['tc'] as String,
      )).toList();

      _filtrele();
    } catch (e) {
      _hata = 'Şoför listesi yüklenirken bir hata oluştu: $e';
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  bool tcKullaniliyor(String tc, {String? mevcutId}) {
    final idInt = mevcutId != null ? int.tryParse(mevcutId) : null;
    return DatabaseService.instance.soforTcExists(tc, excludeId: idInt);
  }

  void ekle({
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    DatabaseService.instance.insertSofor(
      ad: ad.trim(),
      soyad: soyad.trim(),
      telefon: telefon.trim(),
      tc: tc.trim(),
    );

    yukle();
  }

  void guncelle({
    required Sofor sofor,
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    final idInt = int.parse(sofor.id);
    DatabaseService.instance.updateSofor(
      id: idInt,
      ad: ad.trim(),
      soyad: soyad.trim(),
      telefon: telefon.trim(),
      tc: tc.trim(),
    );
    yukle();
  }

  void sil(String id) {
    final idInt = int.parse(id);
    DatabaseService.instance.deleteSofor(idInt);
    yukle();
  }

  void _filtrele() {
    if (_aramaMetni.isEmpty) {
      _filtreliSoforler = List.from(_tumSoforler);
    } else {
      _filtreliSoforler = _tumSoforler.where((s) {
        return s.tamAd.toLowerCase().contains(_aramaMetni) ||
            s.telefon.contains(_aramaMetni) ||
            s.tc.contains(_aramaMetni);
      }).toList();
    }
  }

  void ara(String query) {
    _aramaMetni = query.toLowerCase().trim();
    _filtrele();
    notifyListeners();
  }

  /// Şoförleri CSV formatında masaüstüne / istenen konuma kaydeder
  Future<String?> disaAktar() async {
    try {
      if (_tumSoforler.isEmpty) {
        return 'Dışa aktarılacak şoför kaydı bulunmuyor.';
      }

      String csvEscape(String value) {
        return '"${value.replaceAll('"', '""')}"';
      }

      final buffer = StringBuffer();
      buffer.writeln('Ad,Soyad,Telefon,TC');

      for (final s in _tumSoforler) {
        buffer.writeln([
          csvEscape(s.ad),
          csvEscape(s.soyad),
          csvEscape(s.telefon),
          csvEscape(s.tc),
        ].join(','));
      }

      final String? savedPath = await FilePicker.saveFile(
        dialogTitle: 'Şoför kayıtlarını dışa aktar',
        fileName: 'soforler.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList([
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode(buffer.toString()),
        ]),
      );

      if (savedPath == null) {
        return 'Dışa aktarma iptal edildi.';
      }

      return 'Şoför kayıtları başarıyla dışa aktarıldı.';
    } catch (e) {
      return 'Dışa aktarma başarısız: $e';
    }
  }

  /// Seçilen CSV dosyasından şoförleri içeri aktarır
  Future<String?> iceAktar() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return 'Dosya seçilmedi.';
      }

      final pickedFile = result.files.single;
      String content;

      if (pickedFile.bytes != null) {
        content = utf8.decode(
          pickedFile.bytes!,
          allowMalformed: true,
        );
      } else if (pickedFile.path != null) {
        content = await File(pickedFile.path!).readAsString();
      } else {
        return 'Seçilen dosyanın içeriği okunamadı.';
      }

      content = content.replaceFirst('\uFEFF', '');

      // CSV hücrelerini tırnak ve virgül kaçışlarına dikkat ederek güvenle ayrıştırır
      final rows = <List<String>>[];
      var row = <String>[];
      var field = StringBuffer();
      var inQuotes = false;

      for (int i = 0; i < content.length; i++) {
        final char = content[i];

        if (char == '"') {
          if (inQuotes &&
              i + 1 < content.length &&
              content[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          row.add(field.toString());
          field = StringBuffer();
        } else if ((char == '\n' || char == '\r') && !inQuotes) {
          if (char == '\r' &&
              i + 1 < content.length &&
              content[i + 1] == '\n') {
            i++;
          }

          row.add(field.toString());

          if (row.any((v) => v.trim().isNotEmpty)) {
            rows.add(row);
          }

          row = <String>[];
          field = StringBuffer();
        } else {
          field.write(char);
        }
      }

      row.add(field.toString());
      if (row.any((v) => v.trim().isNotEmpty)) {
        rows.add(row);
      }

      if (rows.length <= 1) {
        return 'CSV boş veya başlık satırı bulunamadı.';
      }

      // Sütun sırası bağımsız olarak başlıkları eşler
      final headers = rows.first
          .map((v) => v.trim().toLowerCase())
          .toList();

      final adIndex = headers.indexOf('ad');
      final soyadIndex = headers.indexOf('soyad');
      final telefonIndex = headers.indexOf('telefon');
      final tcIndex = headers.indexOf('tc');

      if (adIndex < 0 ||
          soyadIndex < 0 ||
          telefonIndex < 0 ||
          tcIndex < 0) {
        return 'CSV başlıkları geçersiz. '
            'Beklenen başlıklar: Ad,Soyad,Telefon,TC';
      }

      int eklenen = 0;
      int atlanan = 0;

      for (final columns in rows.skip(1)) {
        final maxIndex = [
          adIndex,
          soyadIndex,
          telefonIndex,
          tcIndex,
        ].reduce((a, b) => a > b ? a : b);

        if (columns.length <= maxIndex) {
          atlanan++;
          continue;
        }

        final ad = columns[adIndex].trim();
        final soyad = columns[soyadIndex].trim();
        final telefon = columns[telefonIndex].trim();
        final tc = columns[tcIndex]
            .trim()
            .replaceAll(RegExp(r'\s+'), '');

        if (ad.isEmpty ||
            soyad.isEmpty ||
            !RegExp(r'^\d{11}$').hasMatch(tc) ||
            tcKullaniliyor(tc)) {
          atlanan++;
          continue;
        }

        DatabaseService.instance.insertSofor(
          ad: ad,
          soyad: soyad,
          telefon: telefon,
          tc: tc,
        );

        eklenen++;
      }

      await yukle();

      return 'İçe aktarma tamamlandı. '
          'Eklenen: $eklenen, atlanan: $atlanan.';
    } catch (e) {
      return 'İçe aktarma hatası: $e';
    }
  }
}