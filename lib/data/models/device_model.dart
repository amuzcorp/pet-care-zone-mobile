class DeviceModel {
  final String? deviceId;
  final String? deviceIp;
  final String serialNumber;
  final String deviceName;

  DeviceModel({
    this.deviceId,
    this.deviceIp,
    required this.serialNumber,
    required this.deviceName,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'],
      serialNumber: json['serialNumber'],
      deviceName: json['deviceName'],
      deviceIp: json['deviceIp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'serialNumber': serialNumber,
      'deviceName': deviceName,
      'deviceIp': deviceIp,
    };
  }

  DeviceModel copyWith({
    String? deviceId,
    String? serialNumber,
    String? deviceName,
    String? deviceIp,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceName: deviceName ?? this.deviceName,
      deviceIp: deviceIp ?? this.deviceIp,
    );
  }
}
