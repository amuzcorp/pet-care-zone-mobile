import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/device_model.dart';

class DeviceService {
  static const platform = MethodChannel('com.lge.petcarezone/discovery');
  final ApiService apiService = ApiService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final MessageService messageService = MessageService();

  Future saveAndInitializeWebOSDevice() async {
    final matchedWebosDevice = connectSdkService.matchedWebosDevice;
    logD.i('matchedWebosDevice $matchedWebosDevice');

    if (matchedWebosDevice.isNotEmpty) {
      /// DeviceModel 생성
      final deviceModel = DeviceModel(
        serialNumber: matchedWebosDevice['modelNumber'],
        deviceName: matchedWebosDevice['friendlyName'],
        deviceIp: matchedWebosDevice['lastKnownIPAddress'],
      );

      /// webOS whole Data 저장
      await saveWebOSDeviceInfo(matchedWebosDevice);
      await deviceInitialize();
      /// webOS necessary Data만 저장
      await saveDeviceInfo(deviceModel);
      connectSdkService.matchedDeviceController.close();
    } else {
      messageService.messageController.add("기기 연결에 실패했어요. 뒤로 이동해\nWi-Fi 연결을 다시 시도해 주세요.");
    }
  }

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

  Future<void> saveBleInfo(BluetoothDevice ble) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> modifiedBle = {
      'scanResult': {
        'device': {
          'remoteId': ble?.remoteId?.toString() ?? '',
          'platformName': ble?.platformName.toString() ?? 'Unknown',
          'services': ble?.servicesList.toString() ?? [],
        },
      }
    };

    String bleJson = jsonEncode(modifiedBle);
    await prefs.setString('ble_info', bleJson);
  }

  Future<void> saveWebOSDeviceInfo(Map<String, dynamic> device) async {
    final prefs = await SharedPreferences.getInstance();
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
    String deviceJson = jsonEncode(modifiedDevice);

    try {
      await prefs.setString('webos_device_info', deviceJson);
      connectSdkService.logStreamController.add("WebOS device info saved: $modifiedDevice");
      logD.i('WebOS device info saved: $modifiedDevice');
    } catch (e) {
      logD.e('Error saving device: $e');
    }
  }

  Future<Map<String, dynamic>> getWebOSDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceJson = prefs.getString('webos_device_info');
    if (deviceJson != null && deviceJson.isNotEmpty) {
      Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
      return deviceMap;
    } else {
      logD.e('No device info found in SharedPreferences');
    }
    return {};
  }

  Future connectToDevice() async {
    final webOSDeviceInfo = await getWebOSDeviceInfo();
    logD.i('webOSDeviceInfo try to connect $webOSDeviceInfo');
    connectSdkService.connectToDevice(webOSDeviceInfo!);
  }

  Future<Map<String, dynamic>> getBleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceJson = prefs.getString('ble_info');
    if (deviceJson != null && deviceJson.isNotEmpty) {
      Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
      return deviceMap;
    } else {
      logD.e('No ble info found in SharedPreferences');
    }
    return {};
  }

  Future<BluetoothDevice?> getConnectedBleDevice() async {
    final bleInfo = await getBleInfo();
    final String remoteId = bleInfo['scanResult']['device']['remoteId'];
    return BluetoothDevice.fromId(remoteId);
  }

  Future<void> saveLocalDeviceInfo(Map<String, dynamic> deviceInfo) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic userData = prefs.getString('user');
    Map<String, dynamic> userMap = jsonDecode(userData);
    userMap['deviceList'].add(deviceInfo);

    String updatedUserData = jsonEncode(userMap);
    await prefs.setString('user', updatedUserData);
  }

  Future<void> saveDeviceInfo(DeviceModel device) async {
    final prefs = await SharedPreferences.getInstance();
    String deviceJson = jsonEncode(device.toJson());
    logD.i('saved device\n$deviceJson');
    bool isSaved = await prefs.setString('selected_device', deviceJson);
    if (isSaved) {
      logD.i('Device saved successfully');
    } else {
      logD.e('Failed to save device');
    }
  }

  Future<DeviceModel?> getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceJson = prefs.getString('selected_device');
    logD.i('deviceJson $deviceJson');
    if (deviceJson != null && deviceJson.isNotEmpty) {
      Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
      return DeviceModel.fromJson(deviceMap);
    }
  }

  Future<Map<String, dynamic>?> registerDevice(deviceId, deviceName, serialNumber) async {
    final result = await apiService.postDeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      serialNumber: serialNumber,
    );
    logD.i('Register Result : $result');
    return result;
  }

  Future<Map<String, dynamic>?> modifyDevice(deviceId, deviceName, serialNumber) async {
    return await apiService.postDeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      serialNumber: serialNumber,
    );
  }

  Future<Map<String, dynamic>?> provisionDevice(String deviceId) async {
    final result = await apiService.postDeviceProvision(
      deviceId: deviceId,
    );
    logD.i('Provision Result : $result');
    return result;
  }
}
