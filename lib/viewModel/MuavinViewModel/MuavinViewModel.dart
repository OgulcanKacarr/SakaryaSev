import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/Muavin/Muavin.dart';
import '../../services/DatabaseService/DatabaseService.dart';
import 'dart:typed_data';

final muavinProvider =
ChangeNotifierProvider<MuavinViewModel>((ref) {
  return MuavinViewModel(DatabaseService.instance);
});

class MuavinViewModel extends ChangeNotifier {
  final DatabaseService _db;

  MuavinViewModel(this._db) {
    yukle();
  }

  List<Muavin> _muavinler = [];
  String _arama = '';

  bool _yukleniyor = true;
  String? _hata;

  List<Muavin> get muavinler {
    final query = _arama.trim().toLowerCase();

    if (query.isEmpty) {
      return List.unmodifiable(_muavinler);
    }

    return _muavinler.where((m) {
      return m.tamAd.toLowerCase().contains(query) ||
          m.telefon.contains(query) ||
          m.tc.contains(query);
    }).toList();
  }

  int get toplamMuavin => _muavinler.length;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  void ara(String value) {
    _arama = value;
    notifyListeners();
  }

  void yukle() {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      _muavinler = _db
          .getAllMuavinler()
          .map(Muavin.fromMap)
          .toList();

      _hata = null;
    } catch (e) {
      _hata = 'Muavin kayıtları yüklenemedi: $e';
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  void ekle({
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    _db.insertMuavin(
      ad: ad.trim(),
      soyad: soyad.trim(),
      telefon: telefon.trim(),
      tc: tc.trim(),
    );

    yukle();
  }

  void guncelle({
    required Muavin muavin,
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    _db.updateMuavin(
      id: muavin.id,
      ad: ad.trim(),
      soyad: soyad.trim(),
      telefon: telefon.trim(),
      tc: tc.trim(),
    );

    yukle();
  }

  void sil(int id) {
    _db.deleteMuavin(id);
    yukle();
  }

  bool tcKullaniliyor(
      String tc, {
        int? mevcutId,
      }) {
    return _db.muavinTcExists(
      tc.trim(),
      excludeId: mevcutId,
    );
  }

  /// Muavinleri CSV formatında masaüstüne dışa aktarır


  Future<String?> disaAktarMasaustune() async {
    try {
      if (_muavinler.isEmpty) {
        return 'Dışa aktarılacak kayıt bulunmuyor.';
      }

      String csvEscape(String value) {
        return '"${value.replaceAll('"', '""')}"';
      }

      final buffer = StringBuffer();
      buffer.writeln('Ad,Soyad,Telefon,TC');

      for (final m in _muavinler) {
        buffer.writeln([
          csvEscape(m.ad),
          csvEscape(m.soyad),
          csvEscape(m.telefon),
          csvEscape(m.tc),
        ].join(','));
      }

      final String? savedPath = await FilePicker.saveFile(
        dialogTitle: 'Muavin kayıtlarını dışa aktar',
        fileName: 'muavinler.csv',
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

      return 'Muavin kayıtları başarıyla dışa aktarıldı.';
    } catch (e) {
      return 'Dışa aktarma başarısız: $e';
    }
  }




  /// Kullanıcının seçtiği dosyadan (CSV) muavinleri içe aktarır

  Future<String?> iceAktarDosyadan() async {
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

      // CSV alanlarını tırnakları ve virgülleri koruyarak ayrıştırır.
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
        } else if ((char == '\n' || char == '\r') &&
            !inQuotes) {
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

      // Başlık sütunlarını bul; sütun sırası farklı olsa da çalışır.
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

        _db.insertMuavin(
          ad: ad,
          soyad: soyad,
          telefon: telefon,
          tc: tc,
        );

        eklenen++;
      }

      yukle();

      return 'İçe aktarma tamamlandı. '
          'Eklenen: $eklenen, atlanan: $atlanan.';
    } catch (e) {
      return 'İçe aktarma hatası: $e';
    }
  }

}