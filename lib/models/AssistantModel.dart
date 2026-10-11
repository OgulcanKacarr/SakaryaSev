class AssistantModel {
  String id;
  String firstName;
  String lastName;
  String phone;
  String tc;

  AssistantModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.tc,
  });

  String get fullName => "$firstName $lastName";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "tc": tc,
    };
  }

  factory AssistantModel.fromJson(Map<String, dynamic> json) {
    return AssistantModel(
      id: json["id"]?.toString() ?? "",
      firstName: json["firstName"]?.toString() ?? "",
      lastName: json["lastName"]?.toString() ?? "",
      phone: json["phone"]?.toString() ?? "",
      tc: json["tc"]?.toString() ?? "",
    );
  }
}