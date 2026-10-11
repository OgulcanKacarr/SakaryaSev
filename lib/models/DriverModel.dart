class DriverModel {
  String id;
  String firstName;
  String lastName;
  String phone;
  String note;

  DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone = "",
    this.note = "",
  });

  String get fullName {
    return "$firstName $lastName".trim();
  }

  factory DriverModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return DriverModel(
      id: json["id"]?.toString() ?? "",
      firstName: json["firstName"]?.toString() ?? "",
      lastName: json["lastName"]?.toString() ?? "",
      phone: json["phone"]?.toString() ?? "",
      note: json["note"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "note": note,
    };
  }
}