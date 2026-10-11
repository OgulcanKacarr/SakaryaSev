class BusAssignmentModel {
  String id;

  // Trioda'dan gelen bölge adı
  String region;

  // Bu bölgeye göre aracın kalkış yeri
  String departure;

  // Bu bölgede araç hangi şoförle eşleşecek?
  String driverId;

  BusAssignmentModel({
    required this.id,
    required this.region,
    required this.departure,
    required this.driverId,
  });

  factory BusAssignmentModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return BusAssignmentModel(
      id: json["id"]?.toString() ?? "",
      region: json["region"]?.toString() ?? "",
      departure: json["departure"]?.toString() ?? "",
      driverId: json["driverId"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "region": region,
      "departure": departure,
      "driverId": driverId,
    };
  }
}