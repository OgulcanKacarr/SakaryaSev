class TripModel {
  String plate;
  String driver;
  String departure;
  String arrival;
  String time;

  int? estimatedDurationMinutes;

  TripModel({
    required this.plate,
    required this.driver,
    required this.departure,
    required this.arrival,
    required this.time,
    this.estimatedDurationMinutes,
  });

  factory TripModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return TripModel(
      plate: json["plate"]?.toString() ?? "",
      driver: json["driver"]?.toString() ?? "",
      departure:
      json["departure"]?.toString() ?? "",
      arrival:
      json["arrival"]?.toString() ?? "",
      time: json["time"]?.toString() ?? "",

      estimatedDurationMinutes:
      json["estimatedDurationMinutes"] == null
          ? null
          : int.tryParse(
        json["estimatedDurationMinutes"]
            .toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "plate": plate,
      "driver": driver,
      "departure": departure,
      "arrival": arrival,
      "time": time,
      "estimatedDurationMinutes":
      estimatedDurationMinutes,
    };
  }
}