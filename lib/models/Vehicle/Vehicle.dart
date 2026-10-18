
class Vehicle {
  final int? id;
  final String plate;
  final String? trioVehicleId;
  final String? brand;
  final String? model;
  final int? year;
  final String? description;
  final bool isActive;

  const Vehicle({
    this.id,
    required this.plate,
    this.trioVehicleId,
    this.brand,
    this.model,
    this.year,
    this.description,
    this.isActive = true,
  });

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as int?,
      plate: map['plate'] as String,
      trioVehicleId: map['trio_vehicle_id'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      year: map['year'] as int?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'plate': plate.trim().toUpperCase(),
      'trio_vehicle_id': trioVehicleId?.trim().isEmpty == true
          ? null
          : trioVehicleId?.trim(),
      'brand': brand,
      'model': model,
      'year': year,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }
}
