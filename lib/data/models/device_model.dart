import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceModel {
  final String? deviceId;
  final String? deviceIp;
  final String serialNumber;
  final String deviceName;
  final Map? bleData;

  DeviceModel({
    this.deviceId,
    this.deviceIp,
    required this.serialNumber,
    required this.deviceName,
    this.bleData,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'],
      serialNumber: json['serialNumber'],
      deviceName: json['deviceName'],
      deviceIp: json['deviceIp'],
      bleData: json['bleData'],
    );
  }

  // BLE 데이터 내 ScanResult와 DeviceIdentifier를 직렬화 가능한 형식으로 변환
  Map<String, dynamic> toJson() {
    // bleData 내 ScanResult를 직렬화 가능한 형식으로 변환
    Map<String, dynamic>? serializedBleData = bleData?.map((key, value) {
      if (value is ScanResult) {
        return MapEntry(key, _convertScanResultToJson(value));
      }
      return MapEntry(key, value);
    });

    return {
      'deviceId': deviceId,
      'serialNumber': serialNumber,
      'deviceName': deviceName,
      'deviceIp': deviceIp,
      'bleData': serializedBleData,
    };
  }

  // ScanResult 객체를 JSON 형식으로 변환하는 헬퍼 메서드
  Map<String, dynamic> _convertScanResultToJson(ScanResult scanResult) {
    return {
      'device': {
        'remoteId': scanResult.device.remoteId.toString(),
        'platformName': scanResult.device.platformName,
        'services': scanResult.device.servicesList,
      },
      'advertisementData': {
        'advName': scanResult.advertisementData.advName,
        'txPowerLevel': scanResult.advertisementData.txPowerLevel,
        'connectable': scanResult.advertisementData.connectable,
        'manufacturerData': scanResult.advertisementData.manufacturerData.map((key, value) =>
            MapEntry(key.toString(), value)),
        'serviceData': scanResult.advertisementData.serviceData.map((key, value) =>
            MapEntry(key.toString(), value)),
        'serviceUuids': scanResult.advertisementData.serviceUuids
            .map((uuid) => uuid.toString())
            .toList(),
      },
      'rssi': scanResult.rssi,
      'timeStamp': scanResult.timeStamp.toString(),
    };
  }

  DeviceModel copyWith({
    String? deviceId,
    String? serialNumber,
    String? deviceName,
    String? deviceIp,
    Map? bleData,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceName: deviceName ?? this.deviceName,
      deviceIp: deviceIp ?? this.deviceIp,
      bleData: bleData ?? this.bleData,
    );
  }
}
