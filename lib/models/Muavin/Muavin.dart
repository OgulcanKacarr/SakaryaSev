
class Muavin {
  final int id;
  final String ad;
  final String soyad;
  final String telefon;
  final String tc;

  const Muavin({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.telefon,
    required this.tc,
  });

  String get tamAd => '$ad $soyad';

  factory Muavin.fromMap(Map<String, Object?> map) {
    return Muavin(
      id: map['id'] as int,
      ad: map['ad'] as String,
      soyad: map['soyad'] as String,
      telefon: map['telefon'] as String,
      tc: map['tc'] as String,
    );
  }
}
