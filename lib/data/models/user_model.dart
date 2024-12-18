import 'pet_model.dart';
import 'device_model.dart';

class UserModel {
  final String accessToken;
  final String userId;
  final String email;
  final String nickname;
  final List<PetModel> petList;
  final List<DeviceModel> deviceList;

  UserModel({
    required this.accessToken,
    required this.userId,
    required this.email,
    required this.nickname,
    required this.petList,
    required this.deviceList,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> petListFromJson = json['petList'] ?? [];
    List<PetModel> petList = petListFromJson.map((pet) => PetModel.fromJson(pet)).toList();

    List<dynamic> deviceListFromJson = json['deviceList'] ?? [];
    List<DeviceModel> deviceList = deviceListFromJson.map((device) => DeviceModel.fromJson(device)).toList();

    return UserModel(
      accessToken: json['accessToken'],
      userId: json['userInfo']['userId'],
      email: json['userInfo']['email'],
      nickname: json['userInfo']['nickname'],
      petList: petList,
      deviceList: deviceList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'userInfo': {
        'userId': userId,
        'email': email,
        'nickname': nickname,
      },
      'petList': petList.map((pet) => pet.toJson()).toList(),
      'deviceList': deviceList.map((device) => device.toJson()).toList(),
    };
  }
}
