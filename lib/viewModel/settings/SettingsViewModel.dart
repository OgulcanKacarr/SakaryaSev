
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/AppSettings/AppSettings.dart';
import '../../models/Vehicle/Vehicle.dart';
import '../../services/SettingsService/SettingsService.dart';
import '../../services/VehicleService/VehicleService.dart';


class SettingsPageViewModel extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService.instance;

  late final StreamSubscription<void> _vehicleChangesSubscription;
  final SettingsService _settingsService = SettingsService.instance;

  List<Vehicle> vehicles = [];
  bool isLoading = false;
  String? errorMessage;

  int get vehicleCount => vehicles.length;


  AppSettings appSettings = const AppSettings();
  bool isSettingsLoading = false;
  String? settingsErrorMessage;


  SettingsPageViewModel() {
    _vehicleChangesSubscription =
        _vehicleService.changes.listen((_) {
          loadVehicles();
        });
  }


  void loadVehicles() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      vehicles = _vehicleService.getAllVehicles();
    } catch (e) {
      errorMessage = 'Araçlar yüklenemedi: $e';
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool addVehicle(Vehicle vehicle) {
    try {
      _vehicleService.addVehicle(vehicle);
      loadVehicles();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool updateVehicle(Vehicle vehicle) {
    try {
      _vehicleService.updateVehicle(vehicle);
      loadVehicles();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool deleteVehicle(int id) {
    try {
      _vehicleService.deleteVehicle(id);
      loadVehicles();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }


  void loadAppSettings() {
    try {
      appSettings = _settingsService.loadSettings();
      settingsErrorMessage = null;
    } catch (e) {
      settingsErrorMessage = 'Ayarlar yüklenemedi: $e';
      debugPrint(settingsErrorMessage);
    }

    notifyListeners();
  }

  void updateAppSettings(AppSettings newSettings) {
    try {
      _settingsService.saveSettings(newSettings);
      appSettings = newSettings;
      settingsErrorMessage = null;
    } catch (e) {
      settingsErrorMessage = 'Ayarlar kaydedilemedi: $e';
      debugPrint(settingsErrorMessage);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _vehicleChangesSubscription.cancel();
    super.dispose();
  }
}
