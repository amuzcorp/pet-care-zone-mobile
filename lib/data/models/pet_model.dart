class PetModel {
  final int petId;
  final String petName;
  final String petImage;
  final int petType;
  final String petTypeName;
  final String birthday;
  final double weight;
  final int genderType;
  final String genderTypeName;
  final String neuterYn;
  final int kindType;
  final String kindTypeName;
  final String deviceId;

  PetModel({
    required this.petId,
    required this.petName,
    required this.petImage,
    required this.petType,
    required this.petTypeName,
    required this.birthday,
    required this.weight,
    required this.genderType,
    required this.genderTypeName,
    required this.neuterYn,
    required this.kindType,
    required this.kindTypeName,
    required this.deviceId,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      petId: json['petId'],
      petName: json['petName'],
      petImage: json['petImage'] ?? '',
      petType: json['petType'],
      petTypeName: json['petTypeName'],
      birthday: json['birthday'],
      weight: json['weight'],
      genderType: json['genderType'],
      genderTypeName: json['genderTypeName'],
      neuterYn: json['neuterYn'],
      kindType: json['kindType'],
      kindTypeName: json['kindTypeName'],
      deviceId: json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'petName': petName,
      'petImage': petImage,
      'petType': petType,
      'petTypeName': petTypeName,
      'birthday': birthday,
      'weight': weight,
      'genderType': genderType,
      'genderTypeName': genderTypeName,
      'neuterYn': neuterYn,
      'kindType': kindType,
      'kindTypeName': kindTypeName,
      'deviceId': deviceId,
    };
  }
}
