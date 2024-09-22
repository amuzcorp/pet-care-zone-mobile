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


  Future requestPincode() async {
    final webOSDeviceInfo = await getWebOSDeviceInfo();
    logD.i('webOSDeviceInfo $webOSDeviceInfo');
    connectSdkService.initializeDevice(webOSDeviceInfo!);
  }

  Future<void> saveWebOSDeviceInfo(Map<String, dynamic> device) async {
    final prefs = await SharedPreferences.getInstance();
    String deviceJson = jsonEncode(device);
    await prefs.setString('webos_device_info', deviceJson);
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
