class Sofor {
  final String id;
  final String ad;
  final String soyad;
  final String telefon;
  final String tc;

  Sofor({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.telefon,
    required this.tc,
  });

  String get tamAd => '$ad $soyad';

  Sofor copyWith({
    String? id,
    String? ad,
    String? soyad,
    String? telefon,
    String? tc,
  }) {
    return Sofor(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      tc: tc ?? this.tc,
    );
  }
}