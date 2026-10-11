import 'BusAssignmentModel.dart';

class BusModel {
  String vehicleId;
  String plate;

  String note;
  bool speakNote;

  bool manualTracking;
  int estimatedArrivalMinutes;

  List<BusAssignmentModel> assignments;

  BusModel({
    required this.vehicleId,
    required this.plate,
    this.note = "",
    this.speakNote = false,
    this.manualTracking = false,
    this.estimatedArrivalMinutes = 0,
    List<BusAssignmentModel>? assignments,
  }) : assignments = assignments ?? [];

  factory BusModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final assignmentsJson =
        json["assignments"] as List<dynamic>? ?? [];

    return BusModel(
      vehicleId: json["vehicleId"]?.toString() ?? "",
      plate: json["plate"]?.toString() ?? "",
      note: json["note"]?.toString() ?? "",
      speakNote: json["speakNote"] ?? false,
      manualTracking: json["manualTracking"] ?? false,
      estimatedArrivalMinutes:
      json["estimatedArrivalMinutes"] ?? 0,
      assignments: assignmentsJson
          .map(
            (e) => BusAssignmentModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "vehicleId": vehicleId,
      "plate": plate,
      "note": note,
      "speakNote": speakNote,
      "manualTracking": manualTracking,
      "estimatedArrivalMinutes":
      estimatedArrivalMinutes,
      "assignments":
      assignments.map((e) => e.toJson()).toList(),
    };
  }
}