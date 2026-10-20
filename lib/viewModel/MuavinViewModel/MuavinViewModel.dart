
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/Muavin/Muavin.dart';
import '../../services/DatabaseService/DatabaseService.dart';

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
}
