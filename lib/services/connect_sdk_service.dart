import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/utils/permissionCheck.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class ConnectSdkService {
  static final ConnectSdkService _instance = ConnectSdkService._internal();
  factory ConnectSdkService() => _instance;

  ConnectSdkService._internal();

  static const MethodChannel channel = MethodChannel('com.lge.petcarezone/discovery');
  static const MethodChannel logChannel = MethodChannel('com.lge.petcarezone/logs');

  final PermissionCheck permissionCheck = PermissionCheck();
  final StreamController<List<Map<String, dynamic>>> deviceStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> bleStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> matchedDeviceController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> logStreamController = StreamController<String>.broadcast();

  StreamSubscription? logSubscription;

  final List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> bleList = [];
  List<String> collectedLogs = [];
  Map<String, dynamic> matchedWebosDevice = {};

  final String log = "";
  Timer? scanTimer;
  Timer? bleScanTimer;

  Stream<List<Map<String, dynamic>>> get deviceStream async* {
    yield devices;
    yield* deviceStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> get bleStream async* {
    yield bleList;
    yield* bleStreamController.stream;
  }

  Stream<Map<String, dynamic>> get matchedDeviceStream async* {
    yield matchedWebosDevice;
    yield* matchedDeviceController.stream;
  }

  Stream<String> get logStream async* {
    yield* logStreamController.stream;
  }

  void updateMatchedDevice(Map<String, dynamic> device) {
    matchedWebosDevice = device;
    matchedDeviceController.add(device);
  }

  void setupLogListener() async {
    logChannel.setMethodCallHandler((MethodCall call) async {
      final result = call.arguments;
      logD.i('connectSDK result : $result');
      logStreamController.add(result);

      if (result.contains('iotDeviceId')) {
        final jsonData = jsonDecode(result);
        /// Provision 완료
        if (jsonData['payload'] != null && jsonData['payload']['iotDeviceId'] != null) {
          logStreamController.add('provision 요청 성공 : ${jsonData['payload']['iotDeviceId']}');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('deviceId', jsonData['payload']['iotDeviceId']);
          logD.i('Device ID has been set : ${prefs.getString('deviceId')}');
        }
      }
    });
  }

  void startLogSubscription(void Function(String data) onData) {
    logSubscription ??= logStream.listen((data) async {
      collectedLogs.add(data);
      onData(data);
    });
  }

  List<String> getAllLogs() {
    return collectedLogs;
  }

  findMatchedDevice() {
    if (bleList.isNotEmpty && devices.isNotEmpty) {
      final matchedDevice = devices.firstWhere((webOSDevice) => bleList.any((bleDevice) =>
        webOSDevice['friendlyName'].trim() == bleDevice['platformName'].trim()),
        orElse: () => {},
      );
      updateMatchedDevice(matchedDevice);
      print('matchedWebosDevice $matchedWebosDevice');
    }
  }


  Future<void> startScan() async {
    scanTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        logD.i("Scanning...");
        findMatchedDevice();

        await channel.invokeMethod('startScan');

      } on PlatformException catch (e) {
        logD.w("Failed to start scan: '${e.message}'.");
        await stopScan();
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

  Future startBleScan() async {
    bleScanTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await FlutterBluePlus.startScan(
        androidScanMode: AndroidScanMode.balanced,
        timeout: const Duration(seconds: 5),
      );
    });

    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        for (ScanResult r in results) {
          final remoteId = r.device.remoteId;
          final platformName = r.device.platformName ?? '';
          final advName = r.advertisementData.advName ?? '';
          final services = r.device.servicesList;

          if (platformName.toLowerCase().contains('pet') || advName.toLowerCase().contains('pet')) {
            final bleData = {
              'remoteId': remoteId,
              'platformName': platformName,
              'services': services,
              'scanResult': r,
            };

            // 중복 확인 및 제거 후 추가
            final existingIndex = bleList.indexWhere((d) => d['remoteId'] == remoteId);
            if (existingIndex != -1) {
              bleList[existingIndex] = bleData;
            } else {
              bleList.add(bleData);
            }
          }
        }
      } else {
        permissionCheck.requestPermission();
      }

      if (!bleStreamController.isClosed) {
        bleStreamController.add(List<Map<String, dynamic>>.from(bleList));
      }

    });
  }

  Future<void> stopBleScan() async {
    if (bleScanTimer != null && bleScanTimer!.isActive) {
      bleScanTimer!.cancel();
      try {
        logD.i("Scan stopped successfully");
      } on PlatformException catch (e) {
        logD.w("Failed to stop scan: '${e.message}'.");
      }
    } else {
      logD.w("Scan timer was not active or already cancelled");
    }
  }

  Future<void> requestParingKey(Map<String, dynamic> device) async {
    try {
      String deviceJson = jsonEncode(device);
      final result = await channel.invokeMethod('requestParingKey', {'device': deviceJson});
      logD.i('request ParingKey : $result');
    } on PlatformException catch (e) {
      logD.w("Failed to request ParingKey: '${e.message}'.");
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

  Future<void> deviceProvision() async {
    try {
      logD.i("deviceProvision!");
      await channel.invokeMethod('deviceProvision');
    } on PlatformException catch (e) {
      logD.w("Failed to send pairing key: '${e.message}'.");
    }
  }

  Future<void> connectToDevice(Map<String, dynamic> device) async {
    try {
      String deviceJson = jsonEncode(device);
      logD.i("connectToDevice!");
      await channel.invokeMethod('connectToDevice', {'device': deviceJson});
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
      switch (call.method) {
        case "webOSRequest":
          logD.i('request ${call.arguments}');
          collectedLogs.add('webOSRequest => ${call.arguments}');
          logStreamController.add(call.arguments);
          // final bool success = call.arguments['success'];
          // final String response = call.arguments['response'];
          // print("request status: $success, Response: $response");
          break;
        case "onDeviceAdded":
        case "onDeviceUpdated":
          final device = Map<String, dynamic>.from(call.arguments);
          final deviceIp = device['lastKnownIPAddress'] as String;
          final String friendlyName = device['friendlyName']?.toLowerCase() ?? '';
          if (friendlyName.contains("pet")) {
            // 기존에 같은 IP를 가진 기기가 있는지 확인
            final existingDeviceIndex = devices.indexWhere((d) => d['lastKnownIPAddress'] == deviceIp);

            if (existingDeviceIndex == -1) {
              devices.add(device);
            } else {
              devices[existingDeviceIndex] = device;
            }

            deviceStreamController.add(List<Map<String, dynamic>>.from(devices));

            logD.i('Devices list updated: $devices');
          }
          break;
        case "onDeviceRemoved":
          final device = Map<String, dynamic>.from(call.arguments);
          logD.i('Device removed: $device');
          devices.removeWhere((d) => d['id'] == device['id']);
          deviceStreamController.add(List<Map<String, dynamic>>.from(devices));
          break;
        case "onDiscoveryFailed":
          logD.e('Discovery failed');
          break;
        default:
          throw MissingPluginException();
      }
    });
  }
}
