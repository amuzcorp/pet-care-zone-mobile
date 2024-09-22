import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:petcarezone/services/device_service.dart';
import '../utils/logger.dart';

class ConnectSdkService {
  static final ConnectSdkService _instance = ConnectSdkService._internal();

  factory ConnectSdkService() => _instance;

  ConnectSdkService._internal();

  static const MethodChannel channel = MethodChannel('com.lge.petcarezone/discovery');
  static const MethodChannel logChannel = MethodChannel('com.lge.petcarezone/logs');

  final StreamController<List<Map<String, dynamic>>> deviceStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<String> logStreamController = StreamController<String>.broadcast();

  final List<Map<String, dynamic>> devices = [];
  final String log = "";
  Timer? scanTimer;

  Stream<List<Map<String, dynamic>>> get deviceStream async* {
    yield devices;
    yield* deviceStreamController.stream;
  }

  Stream<String> get logStream async* {
    yield* logStreamController.stream;
  }

  void setupLogListener() async {
    logChannel.setMethodCallHandler((MethodCall call) async {
      final result = call.arguments;
      if (result.contains('error')) {
        print('error result : $result');
        logStreamController.add(result);
        logD.i("stream : $logStreamController");
      } else {
        print('none error result : $call');
      }
    });
  }


  Future<void> startScan() async {
    scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        logD.i("Scanning started");
        await channel.invokeMethod('startScan');
      } on PlatformException catch (e) {
        logD.w("Failed to start scan: '${e.message}'.");
        stopScan();
      }
    });
  }

  Future<void> stopScan() async {
    if (scanTimer != null && scanTimer!.isActive) {
      scanTimer!.cancel();
      try {
        await channel.invokeMethod('stopScan');
        logD.i("Scan stopped successfully");
      } on PlatformException catch (e) {
        logD.w("Failed to stop scan: '${e.message}'.");
      }
      logD.i("Scan timer cancelled");
    } else {
      logD.w("Scan timer was not active or already cancelled");
    }
  }

  Future<void> sendPairingKey(String pinCode) async {
    try {
      logD.i("Sending pairing key: $pinCode");
      await channel.invokeMethod('sendPairingKey', {'pinCode': pinCode});
    } on PlatformException catch (e) {
      logD.w("Failed to send pairing key: '${e.message}'.");
    }
  }

  Future<void> initializeDevice(Map<String, dynamic> device) async {
    try {
      String deviceJson = jsonEncode(device);
      final result = await channel.invokeMethod('initialize', {'device': deviceJson});
      logD.i('Device initialization result: $result');
    } on PlatformException catch (e) {
      logD.w("Failed to initialize device: '${e.message}'.");
    }
  }

  void setupListener() {
    channel.setMethodCallHandler((MethodCall call) async {
      logD.i('Method call received: ${call.method}');
      switch (call.method) {
        case "onDeviceAdded":
        case "onDeviceUpdated":
          final device = Map<String, dynamic>.from(call.arguments);
          final deviceIp = device['lastKnownIPAddress'] as String;

          final existingDeviceIndex = devices.indexWhere((d) => d['lastKnownIPAddress'] == deviceIp);

          if (existingDeviceIndex == -1) {
            devices.add(device);
          } else {
            devices[existingDeviceIndex] = device;
          }

          deviceStreamController.add(List<Map<String, dynamic>>.from(devices));
          logD.i('Devices list updated: $devices');
          break;
        case "onDeviceRemoved":
          final device = Map<String, dynamic>.from(call.arguments);
          logD.i('Device removed: $device');
          devices.removeWhere((d) => d['id'] == device['id']);
          deviceStreamController.add(List<Map<String, dynamic>>.from(devices));
          logD.i('Devices list updated: $devices');
          break;
        case "onDiscoveryFailed":
          logD.e('Discovery failed');
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  void dispose() async {
    await stopScan();
    await deviceStreamController.close();
    await logStreamController.close();
  }
}
