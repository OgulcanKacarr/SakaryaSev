import 'package:flutter/material.dart';
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
      ad: ad,
      soyad: soyad,
      telefon: telefon,
      tc: tc,
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
      ad: ad,
      soyad: soyad,
      telefon: telefon,
      tc: tc,
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
}