import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/device_model.dart';

class DeviceService {
  static const platform = MethodChannel('com.lge.petcarezone/discovery');
  final ApiService apiService = ApiService();
  final ConnectSdkService connectSdkService = ConnectSdkService();

  Future deviceInitialize() async {
    final webOSDeviceInfo = await getWebOSDeviceInfo();
    logD.i('webOSDeviceInfo $webOSDeviceInfo');
    connectSdkService.initializeDevice(webOSDeviceInfo!);
  }

  Future requestPincode() async {
    final webOSDeviceInfo = await getWebOSDeviceInfo();
    logD.i('webOSDeviceInfo $webOSDeviceInfo');
    connectSdkService.requestParingKey(webOSDeviceInfo!);
  }

  // Future<void> saveBleInfo(Map<String, dynamic> ble) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   Map<String, dynamic> modifiedBle = {
  //     'remoteId': ble['remoteId']?.toString() ?? '',
  //     'platformName': ble['platformName'] ?? 'Unknown',
  //     'services': ble['services'] ?? [],
  //     'scanResult': {
  //       'device': {
  //         'remoteId': ble['scanResult']?.device?.remoteId?.toString() ?? '',
  //         'platformName': ble['scanResult']?.device?.platformName ?? 'Unknown',
  //         'services': ble['scanResult']?.device?.servicesList ?? [],
  //
  //       },
  //       'advertisementData': {
  //         'advName': ble['scanResult']?.advertisementData?.advName ?? 'Unknown',
  //         'txPowerLevel': ble['scanResult']?.advertisementData?.txPowerLevel ?? 0,
  //         'appearance': ble['scanResult']?.advertisementData?.appearance ?? 0,
  //         'connectable': ble['scanResult']?.advertisementData?.connectable ?? false,
  //         'manufacturerData': ble['scanResult']?.advertisementData?.manufacturerData?.map((key, value) =>
  //             MapEntry(key.toString(), value)) ?? {},
  //         'serviceData': ble['scanResult']?.advertisementData?.serviceData?.map((key, value) =>
  //             MapEntry(key.toString(), value)) ?? {},
  //         'serviceUuids': ble['scanResult']?.advertisementData?.serviceUuids
  //             ?.map((uuid) => uuid.toString())
  //             .toList() ?? [],
  //       },
  //       'rssi': ble['scanResult']?.rssi ?? 0,
  //       'timeStamp': ble['scanResult']?.timeStamp?.toString() ?? '',
  //     }
  //   };
  //
  //   String bleJson = jsonEncode(modifiedBle);
  //   await prefs.setString('ble_info', bleJson);
  // }

  Future<void> saveWebOSDeviceInfo(Map<String, dynamic> device) async {
    final prefs = await SharedPreferences.getInstance();

    // WebOS Device 데이터를 변환
    Map<String, dynamic> modifiedDevice = {
      'id': device['id'] ?? '',
      'lastKnownIPAddress': device['lastKnownIPAddress'] ?? '',
      'friendlyName': device['friendlyName'] ?? 'Unknown',
      'modelName': device['modelName'] ?? 'Unknown',
      'modelNumber': device['modelNumber'] ?? 'Unknown',
      'lastConnected': device['lastConnected'] ?? 0,
      'lastDetection': device['lastDetection'] ?? 0,
      'services': device['services']?.map((key, value) => MapEntry(key.toString(), value)) ?? {},
    };

    // BLE 데이터가 있는 경우 변환
    // if (device['bleData'] != null) {
    //   Map<String, dynamic> bleData = {
    //     'remoteId': device['bleData']['remoteId']?.toString() ?? '',
    //     'platformName': device['bleData']['platformName'] ?? 'Unknown',
    //     'services': device['bleData']['services'] ?? [],
    //     'scanResult': {
    //       'device': {
    //         'remoteId': device['bleData']['scanResult']?.device?.remoteId?.toString() ?? '',
    //         'platformName': device['bleData']['scanResult']?.device?.platformName ?? 'Unknown',
    //         'services': device['bleData']['scanResult']?.device?.servicesList ?? [],
    //       },
    //       'advertisementData': {
    //         'advName': device['bleData']['scanResult']?.advertisementData?.advName ?? 'Unknown',
    //         'txPowerLevel': device['bleData']['scanResult']?.advertisementData?.txPowerLevel ?? 0,
    //         'appearance': device['bleData']['scanResult']?.advertisementData?.appearance ?? 0,
    //         'connectable': device['bleData']['scanResult']?.advertisementData?.connectable ?? false,
    //         'manufacturerData': device['bleData']['scanResult']?.advertisementData?.manufacturerData?.map((key, value) =>
    //             MapEntry(key.toString(), value)) ?? {},
    //         'serviceData': device['bleData']['scanResult']?.advertisementData?.serviceData?.map((key, value) =>
    //             MapEntry(key.toString(), value)) ?? {},
    //         'serviceUuids': device['bleData']['scanResult']?.advertisementData?.serviceUuids
    //             ?.map((uuid) => uuid.toString())
    //             .toList() ?? [],
    //       },
    //       'rssi': device['bleData']['scanResult']?.rssi ?? 0,
    //       'timeStamp': device['bleData']['scanResult']?.timeStamp?.toString() ?? '',
    //     },
    //   };
    //
    //   modifiedDevice['bleData'] = bleData;
    // }

    // JSON으로 변환 후 저장
    try {
      String deviceJson = jsonEncode(modifiedDevice);
      await prefs.setString('webos_device_info', deviceJson);
      print('WebOS device info saved: $modifiedDevice');
    } catch (e) {
      logD.e('Error saving device: $e');
    }

  }

  Future<Map<String, dynamic>> getWebOSDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceJson = prefs.getString('webos_device_info');
      if (deviceJson != null && deviceJson.isNotEmpty) {
        Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
        return deviceMap;
      } else {
        print('No device info found in SharedPreferences');
      }
    } catch (e) {
      logD.e('Error fetching device info: $e');
    }
    return {};
  }


  Future<String?> getDeviceIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceJson = prefs.getString('selected_device');
      if (deviceJson != null && deviceJson.isNotEmpty) {
        Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
        return deviceMap['deviceIp'];
      }
    } catch (e) {
      logD.e('Error retrieving device ID: $e');
    }
    return null;
  }

  Future<void> saveDeviceInfo(DeviceModel device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String deviceJson = jsonEncode(device.toJson());
      logD.i('saved device\n$deviceJson');

      bool isSaved = await prefs.setString('selected_device', deviceJson);

      if (isSaved) {
        logD.i('Device saved successfully');
      } else {
        logD.e('Failed to save device');
      }
    } catch (e) {
      logD.e('Error saving device: $e');
    }
  }

  Future<DeviceModel?> getDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceJson = prefs.getString('selected_device');
      logD.i('deviceJson $deviceJson');
      if (deviceJson != null && deviceJson.isNotEmpty) {
        Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
        return DeviceModel.fromJson(deviceMap);
      }
    } catch (e) {
      logD.e('Error fetching device info: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> registerDevice(DeviceModel device) async {
    print('device ${device.deviceId}');
    try {
      return await apiService.postDeviceInfo(
        deviceId: device.deviceId!,
        deviceName: device.deviceName!,
        serialNumber: device.serialNumber!,
      );
    } catch (e) {
      logD.e('Error registering device: $e');
    }
  }

  Future<Map<String, dynamic>?> modifyDevice(deviceId, deviceName, serialNumber) async {
    try {
      return await apiService.postDeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        serialNumber: serialNumber,
      );
    } catch (e) {
      logD.e('Error  device: $e');
    }
  }

  Future<Map<String, dynamic>?> provisionDevice(String deviceId) async {
    try {
      final result = await apiService.postDeviceProvision(
        deviceId: deviceId,
      );
      print('rererereresult $result');
      return result;
    } catch (e) {
      logD.e('Error provisioning device: $e');
    }
  }
}
