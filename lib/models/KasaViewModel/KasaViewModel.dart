import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../services/DatabaseService/DatabaseService.dart';

final kasaProvider = ChangeNotifierProvider((ref) => KasaViewModel());

class KasaKalemiModel {
  String baslik;
  double tutar;
  bool sabit;

  KasaKalemiModel({
    required this.baslik,
    required this.tutar,
    this.sabit = false,
  });
}

class KasaViewModel extends ChangeNotifier {
  DateTime _seciliTarih = DateTime.now();
  bool _yukleniyor = false;
  String? _hata;
  String _aciklama = '';

  final List<KasaKalemiModel> _gelirler = [
    KasaKalemiModel(baslik: 'TERMINAL', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'ÇARŞI', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'KARASU', tutar: 0.0, sabit: true),
  ];

  final List<KasaKalemiModel> _giderler = [
    KasaKalemiModel(baslik: 'TERMINAL (KASA POS)', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'ÇARŞI (POS)', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'ÇIKIŞLAR', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'ÇARŞI SERVİS', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'AÇIKLAMALI BİLET FARKLARI', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'HAMZA Ç.', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'YUSUF Ç.', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'TALHA Ç.', tutar: 0.0, sabit: true),
    KasaKalemiModel(baslik: 'YÜKSEL', tutar: 0.0, sabit: true),
  ];

  DateTime get seciliTarih => _seciliTarih;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  String get aciklama => _aciklama;

  List<KasaKalemiModel> get gelirler => _gelirler;
  List<KasaKalemiModel> get giderler => _giderler;

  double get toplamGelir => _gelirler.fold(0, (sum, item) => sum + item.tutar);
  double get toplamGider => _giderler.fold(0, (sum, item) => sum + item.tutar);
  double get kalanNakit => toplamGelir - toplamGider;

  KasaViewModel() {
    yukle();
  }

  // Tarihi YYYY-MM-DD formatına kolayca çevirir
  String get tarihFormatli {
    final y = _seciliTarih.year.toString().padLeft(4, '0');
    final m = _seciliTarih.month.toString().padLeft(2, '0');
    final d = _seciliTarih.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Ekranda okunabilir şık gösterim (Örn: 20 Ekim 2026 Salı)
  String get tarihOkunabilir {
    const aylar = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    final gunStr = gunler[_seciliTarih.weekday - 1];
    final ayStr = aylar[_seciliTarih.month];
    return '${_seciliTarih.day} $ayStr ${_seciliTarih.year}, $gunStr';
  }

  void tarihDegistir(DateTime yeniTarih) {
    _seciliTarih = yeniTarih;
    yukle();
  }

  void aciklamaGuncelle(String val) {
    _aciklama = val;
    notifyListeners();
  }

  void gelirTutarGuncelle(int index, double tutar) {
    _gelirler[index].tutar = tutar;
    notifyListeners();
  }

  void giderTutarGuncelle(int index, double tutar) {
    _giderler[index].tutar = tutar;
    notifyListeners();
  }

  void ekstraGiderEkle(String baslik, double tutar) {
    _giderler.add(KasaKalemiModel(baslik: baslik.toUpperCase(), tutar: tutar, sabit: false));
    notifyListeners();
  }

  void giderSil(int index) {
    if (!_giderler[index].sabit) {
      _giderler.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> yukle() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      final tarihStr = tarihFormatli;
      final kasaData = DatabaseService.instance.getKasaByTarih(tarihStr);

      for (var item in _gelirler) {
        item.tutar = 0.0;
      }
      _giderler.removeWhere((item) => !item.sabit);
      for (var item in _giderler) {
        item.tutar = 0.0;
      }
      _aciklama = '';

      if (kasaData != null) {
        final kasaId = kasaData['id'] as int;
        _aciklama = (kasaData['aciklama'] as String?) ?? '';

        final kalemler = DatabaseService.instance.getKasaKalemleri(kasaId);

        for (var k in kalemler) {
          final tur = k['tur'] as String? ?? '';
          final baslik = k['baslik'] as String? ?? '';
          final tutar = (k['tutar'] as num?)?.toDouble() ?? 0.0;

          if (tur == 'GELIR') {
            final idx = _gelirler.indexWhere((e) => e.baslik == baslik);
            if (idx != -1) _gelirler[idx].tutar = tutar;
          } else if (tur == 'GIDER') {
            final idx = _giderler.indexWhere((e) => e.baslik == baslik);
            if (idx != -1) {
              _giderler[idx].tutar = tutar;
            } else {
              _giderler.add(KasaKalemiModel(baslik: baslik, tutar: tutar, sabit: false));
            }
          }
        }
      }
    } catch (e) {
      _hata = 'Kasa verileri yüklenirken hata oluştu: $e';
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  Future<bool> kaydet() async {
    try {
      final tarihStr = tarihFormatli;

      final gelirList = _gelirler
          .map((e) => {'baslik': e.baslik, 'tutar': e.tutar})
          .toList();

      final giderList = _giderler
          .map((e) => {'baslik': e.baslik, 'tutar': e.tutar})
          .toList();

      DatabaseService.instance.saveKasa(
        tarih: tarihStr,
        aciklama: _aciklama,
        gelirler: gelirList,
        giderler: giderList,
      );

      return true;
    } catch (e) {
      _hata = 'Kaydetme hatası: $e';
      notifyListeners();
      return false;
    }
  }
}