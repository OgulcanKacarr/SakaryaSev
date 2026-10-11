import 'package:flutter/material.dart';

import '../models/AnnouncementModel.dart';
import '../models/BusModel.dart';
import '../models/TripModel.dart';



class HomePageViewModel extends ChangeNotifier {

  final List<AnnouncementModel> announcements = [];
  String extractPlate(String summary) {
    final regex = RegExp(r'\d{2}\s+[A-Z]+\s+\d+');

    final match = regex.firstMatch(summary);

    if (match == null) {
      return "";
    }

    return match.group(0)!.trim();
  }

  String findPlate(
      String vehicleId,
      List<BusModel> buses,
      ) {

    debugPrint("Aranan VehicleId : $vehicleId");

    for (final bus in buses) {
      debugPrint("${bus.plate} -> ${bus.vehicleId}");
    }

    try {
      return buses.firstWhere(
            (e) => e.vehicleId == vehicleId,
      ).plate;
    } catch (_) {
      debugPrint("VehicleId eşleşmedi.");
      return "";
    }
  }

  AnnouncementModel? createAnnouncement({

    required Map<String,dynamic> webhook,

    required List<BusModel> buses,

    required List<TripModel> trips,

  }){

    final vehicleId=
    webhook["violation"]["vehicle"]["_id"];

    final region=
    webhook["violation"]["region"]["label"];

    final ts=
    DateTime.parse(
        webhook["violation"]["ts"]
    );

    final plate=
    findPlate(vehicleId,buses);

    if(plate.isEmpty){
      return null;
    }

    TripModel? trip;

    try{

      trip=
          trips.firstWhere(
                  (e)=>e.plate==plate
          );

    }catch(_){}

    return AnnouncementModel(

      plate: plate,

      driver: trip?.driver ?? "",

      departure: trip?.departure ?? "",

      region: region,

      time: ts,

    );

  }

  void addAnnouncement(AnnouncementModel announcement) {

    announcements.insert(0, announcement);

    if (announcements.length > 200) {
      announcements.removeLast();
    }

    notifyListeners();
  }

  List<AnnouncementModel> getByDeparture(String departure) {
    return announcements
        .where((e) => e.departure == departure)
        .toList();
  }



}