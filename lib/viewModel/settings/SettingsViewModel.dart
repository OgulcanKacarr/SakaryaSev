import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/AnnouncementModel.dart';
import '../../models/AssistantModel.dart';
import '../../models/BusAssignmentModel.dart';
import '../../models/BusModel.dart';
import '../../models/DriverModel.dart';
import '../../models/TripModel.dart';
import '../../services/SharedPrefService.dart';

class SettingsPageViewModel extends ChangeNotifier {
  List<BusModel> buses = [];
  List<TripModel> trips = [];

  bool notification = true;
  bool voice = true;

  bool speakDriver = true;
  bool speakDeparture = true;
  bool speakPlate = true;
  bool speakRegion = true;

  List<DriverModel> drivers = [];

  String voiceType = "Kadın";

  String webhookUrl = "https://www.sakaryasevturizm.com/acswhook";
  List<AssistantModel> assistants = [];

  void setSpeakDriver(bool value) {
    speakDriver = value;
    notifyListeners();
  }

  void setSpeakDeparture(bool value) {
    speakDeparture = value;
    notifyListeners();
  }

  void setSpeakPlate(bool value) {
    speakPlate = value;
    notifyListeners();
  }

  void setSpeakRegion(bool value) {
    speakRegion = value;
    notifyListeners();
  }

  void setNotification(bool value) {
    notification = value;
    notifyListeners();
  }

  void setVoice(bool value) {
    voice = value;
    notifyListeners();
  }

  void setVoiceType(String value) {
    voiceType = value;
    notifyListeners();
  }

  Future<void> setWebhookUrl(String value) async {
    webhookUrl = value.trim();

    await SharedPrefService.saveStringWithoutDialog(
      "webhookUrl",
      webhookUrl,
    );

    notifyListeners();
  }

  Future<void> loadBuses() async {
    try {
      final jsonString =
      await SharedPrefService.readString("buses");

      final List<dynamic> list = jsonDecode(jsonString);

      buses = list
          .map((e) => BusModel.fromJson(e))
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveBuses() async {
    final jsonString = jsonEncode(
      buses.map((e) => e.toJson()).toList(),
    );

    await SharedPrefService.saveStringWithoutDialog(
      "buses",
      jsonString,
    );
  }

  Future<void> addBus(BusModel bus) async {
    buses.add(bus);
    await saveBuses();
    notifyListeners();
  }

  Future<void> removeBus(BusModel bus) async {
    buses.remove(bus);
    await saveBuses();
    notifyListeners();
  }

  Future<void> updateVehicleId({
    required String plate,
    required String vehicleId,
  }) async {
    final index = buses.indexWhere(
          (e) => e.plate.toUpperCase() == plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].vehicleId = vehicleId;

    await saveBuses();
    notifyListeners();
  }

  Future<void> loadTrips() async {
    try {
      final jsonString =
      await SharedPrefService.readString("trips");

      final List<dynamic> list = jsonDecode(jsonString);

      trips = list
          .map((e) => TripModel.fromJson(e))
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveTrips() async {
    final jsonString = jsonEncode(
      trips.map((e) => e.toJson()).toList(),
    );

    await SharedPrefService.saveStringWithoutDialog(
      "trips",
      jsonString,
    );
  }

  Future<void> addTrip(TripModel trip) async {
    trips.add(trip);

    trips.sort(
          (a, b) => a.time.compareTo(b.time),
    );

    await saveTrips();
    notifyListeners();
  }

  Future<void> removeTrip(TripModel trip) async {
    trips.remove(trip);

    await saveTrips();
    notifyListeners();
  }

  List<TripModel> getTripsByPlate(String plate) {
    return trips
        .where(
          (e) => e.plate.toUpperCase() ==
          plate.toUpperCase(),
    )
        .toList();
  }

  TripModel? findTrip({
    required String plate,
    required DateTime webhookTime,
  }) {
    final plateTrips = getTripsByPlate(plate);

    if (plateTrips.isEmpty) {
      return null;
    }

    TripModel? selected;

    int webhookMinutes =
        webhookTime.hour * 60 + webhookTime.minute;

    int smallestDifference = 999999;

    for (final trip in plateTrips) {
      final parts = trip.time.split(":");

      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) continue;

      final tripMinutes = hour * 60 + minute;

      if (tripMinutes <= webhookMinutes) {
        final difference =
            webhookMinutes - tripMinutes;

        if (difference < smallestDifference) {
          smallestDifference = difference;
          selected = trip;
        }
      }
    }

    return selected;
  }

  DriverModel? getDriverById(
      String driverId,
      ) {
    try {
      return drivers.firstWhere(
            (e) => e.id == driverId,
      );
    } catch (_) {
      return null;
    }
  }

  BusAssignmentModel? findBusAssignment({
    required String plate,
    required String region,
    String? departure,
  }) {
    final busIndex = buses.indexWhere(
          (e) =>
      e.plate.toUpperCase() ==
          plate.toUpperCase(),
    );

    if (busIndex == -1) {
      return null;
    }

    final bus = buses[busIndex];

    final normalizedRegion =
    region.trim().toUpperCase();

    final normalizedDeparture =
    departure?.trim().toUpperCase();

    for (final assignment in bus.assignments) {
      final regionMatches =
          assignment.region.trim().toUpperCase() ==
              normalizedRegion;

      final departureMatches =
          normalizedDeparture == null ||
              normalizedDeparture.isEmpty ||
              assignment.departure.trim().toUpperCase() ==
                  normalizedDeparture;

      if (regionMatches && departureMatches) {
        return assignment;
      }
    }

    return null;
  }

  String buildAnnouncementText(
      AnnouncementModel announcement,
      ) {
    final List<String> parts = [];

    // ------------------------------------------------------------
    // Atanmış şoförü bul
    // ------------------------------------------------------------

    String driverName = announcement.driver;

    final assignment = findBusAssignment(
      plate: announcement.plate,
      region: announcement.region,
      departure: announcement.departure,
    );

    if (assignment != null) {
      final assignedDriver = getDriverById(
        assignment.driverId,
      );

      if (assignedDriver != null) {
        driverName = assignedDriver.fullName;
      }
    }

    // ------------------------------------------------------------
    // Kalkış
    // ------------------------------------------------------------

    if (speakDeparture &&
        announcement.departure.trim().isNotEmpty) {
      parts.add(
        "${announcement.departure} kalkışlı",
      );
    }

    // ------------------------------------------------------------
    // Şoför
    // ------------------------------------------------------------

    if (speakDriver &&
        driverName.trim().isNotEmpty) {
      parts.add(
        "$driverName şoförünün kullandığı",
      );
    }

    // ------------------------------------------------------------
    // Plaka
    // ------------------------------------------------------------

    if (speakPlate &&
        announcement.plate.trim().isNotEmpty) {
      parts.add(
        "${announcement.plate} plakalı araç",
      );
    }

    // ------------------------------------------------------------
    // Bölge
    // ------------------------------------------------------------

    if (speakRegion &&
        announcement.region.trim().isNotEmpty) {
      parts.add(
        "${announcement.region} bölgesine giriş yaptı.",
      );
    }

    return parts.join(" ");
  }

  void showAddBusDialog(
      BuildContext context,
      SettingsPageViewModel vm,
      ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Araç"),
          content: SizedBox(
            width: 350,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Plaka",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            FilledButton(
              onPressed: () async {
                final plate =
                controller.text.trim().toUpperCase();

                if (plate.isEmpty) return;

                await vm.addBus(
                  BusModel(
                    vehicleId: "",
                    plate: plate,
                  ),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBusNote({
    required String plate,
    required String note,
  }) async {
    final index = buses.indexWhere(
          (e) => e.plate.toUpperCase() == plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].note = note;

    await saveBuses();

    notifyListeners();
  }

  Future<void> setBusNoteSpeech({
    required String plate,
    required bool value,
  }) async {
    final index = buses.indexWhere(
          (e) => e.plate.toUpperCase() == plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].speakNote = value;

    await saveBuses();
    notifyListeners();
  }

  Future<void> loadWebhookUrl() async {
    try {
      final savedUrl =
      await SharedPrefService.readString(
        "webhookUrl",
      );

      if (savedUrl.trim().isNotEmpty) {
        webhookUrl = savedUrl.trim();
      }
    } catch (_) {}

    notifyListeners();
  }
  Future<void> updateManualTracking({
    required String plate,
    required bool enabled,
    required int minutes,
  }) async {
    final index = buses.indexWhere(
          (e) => e.plate.toUpperCase() == plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].manualTracking = enabled;
    buses[index].estimatedArrivalMinutes = minutes;

    await saveBuses();

    notifyListeners();
  }

  Future<void> loadAssistants() async {
    try {
      final jsonString =
      await SharedPrefService.readString("assistants");

      final List<dynamic> list =
      jsonDecode(jsonString);

      assistants = list
          .map((e) => AssistantModel.fromJson(e))
          .toList();

      notifyListeners();
    } catch (_) {
      assistants = [];
    }
  }
  Future<void> saveAssistants() async {
    final jsonString = jsonEncode(
      assistants.map((e) => e.toJson()).toList(),
    );

    await SharedPrefService.saveStringWithoutDialog(
      "assistants",
      jsonString,
    );
  }
  Future<void> addAssistant(
      AssistantModel assistant) async {
    assistants.add(assistant);

    await saveAssistants();

    notifyListeners();
  }
  Future<void> removeAssistant(
      AssistantModel assistant) async {
    assistants.removeWhere(
          (e) => e.id == assistant.id,
    );

    await saveAssistants();

    notifyListeners();
  }
  Future<void> updateAssistant(
      AssistantModel assistant) async {
    final index = assistants.indexWhere(
          (e) => e.id == assistant.id,
    );

    if (index == -1) return;

    assistants[index] = assistant;

    await saveAssistants();

    notifyListeners();
  }

  Future<void> loadDrivers() async {
    try {
      final jsonString =
      await SharedPrefService.readString("drivers");

      final List<dynamic> list =
      jsonDecode(jsonString);

      drivers = list
          .map(
            (e) => DriverModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();

      notifyListeners();
    } catch (_) {
      drivers = [];
    }
  }

  Future<void> saveDrivers() async {
    final jsonString = jsonEncode(
      drivers.map((e) => e.toJson()).toList(),
    );

    await SharedPrefService.saveStringWithoutDialog(
      "drivers",
      jsonString,
    );
  }

  Future<void> addDriver(
      DriverModel driver,
      ) async {
    drivers.add(driver);

    await saveDrivers();

    notifyListeners();
  }

  Future<void> removeDriver(
      DriverModel driver,
      ) async {
    drivers.removeWhere(
          (e) => e.id == driver.id,
    );

    await saveDrivers();

    notifyListeners();
  }

  Future<void> updateDriver(
      DriverModel driver,
      ) async {
    final index = drivers.indexWhere(
          (e) => e.id == driver.id,
    );

    if (index == -1) return;

    drivers[index] = driver;

    await saveDrivers();

    notifyListeners();
  }

  Future<void> addBusAssignment({
    required String plate,
    required String region,
    required String departure,
    required String driverId,
  }) async {
    final index = buses.indexWhere(
          (e) =>
      e.plate.toUpperCase() ==
          plate.toUpperCase(),
    );

    if (index == -1) return;

    final assignment =
    BusAssignmentModel(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      region: region.trim(),
      departure: departure.trim(),
      driverId: driverId,
    );

    buses[index].assignments.add(
      assignment,
    );

    await saveBuses();

    notifyListeners();
  }
  Future<void> removeBusAssignment({
    required String plate,
    required String assignmentId,
  }) async {
    final index = buses.indexWhere(
          (e) =>
      e.plate.toUpperCase() ==
          plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].assignments.removeWhere(
          (e) => e.id == assignmentId,
    );

    await saveBuses();

    notifyListeners();
  }
  Future<void> updateBusAssignment({
    required String plate,
    required String assignmentId,
    required String region,
    required String departure,
    required String driverId,
  }) async {
    final busIndex = buses.indexWhere(
          (e) =>
      e.plate.toUpperCase() ==
          plate.toUpperCase(),
    );

    if (busIndex == -1) return;

    final assignmentIndex =
    buses[busIndex].assignments.indexWhere(
          (e) => e.id == assignmentId,
    );

    if (assignmentIndex == -1) return;

    buses[busIndex].assignments[
    assignmentIndex
    ] = BusAssignmentModel(
      id: assignmentId,
      region: region.trim(),
      departure: departure.trim(),
      driverId: driverId,
    );

    await saveBuses();

    notifyListeners();
  }
  Future<void> deleteBusNote({
    required String plate,
  }) async {
    final index = buses.indexWhere(
          (e) => e.plate.toUpperCase() == plate.toUpperCase(),
    );

    if (index == -1) return;

    buses[index].note = "";
    buses[index].speakNote = false;

    await saveBuses();

    notifyListeners();
  }

}