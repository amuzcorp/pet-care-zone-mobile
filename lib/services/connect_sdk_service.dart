import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../utils/logger.dart';

class ConnectSdkService {
  static final ConnectSdkService _instance = ConnectSdkService._internal();

  factory ConnectSdkService() => _instance;

  ConnectSdkService._internal();

  static const MethodChannel channel = MethodChannel('com.lge.petcarezone/discovery');
  static const MethodChannel logChannel = MethodChannel('com.lge.petcarezone/logs');

  final StreamController<List<Map<String, dynamic>>> deviceStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<String> logStreamController = StreamController<String>.broadcast();
  final StreamController<List<Map<String, dynamic>>> bleStreamController = StreamController.broadcast();

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;


  final List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> bleList = [];
  List<Map<String, dynamic>> lastDeviceList = [];
  final String log = "";
  Timer? scanTimer;
  Timer? bleScanTimer;

  Stream<List<Map<String, dynamic>>> get deviceStream async* {
    yield devices;
    yield* deviceStreamController.stream;
  }

  Stream<String> get logStream async* {
    yield* logStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> get bleStream async* {
    yield bleList;
    yield* bleStreamController.stream;
  }

  Future bleStartScan() async {
    bleScanTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await FlutterBluePlus.startScan(
        androidScanMode: AndroidScanMode.balanced,
        timeout: const Duration(seconds: 5),
      );
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
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
            // print('ble data $bleData');

            // 중복 확인 및 제거 후 추가
            final existingIndex = bleList.indexWhere((d) => d['remoteId'] == remoteId);
            if (existingIndex != -1) {
              bleList[existingIndex] = bleData;
            } else {
              bleList.add(bleData);
            }
          }
        }
      }


      if (!bleStreamController.isClosed) {
        bleStreamController.add(List<Map<String, dynamic>>.from(bleList));
      }

    });
    combineStreams();
  }

  Future combineStreams() async {
    CombineLatestStream.combine2<List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
      bleStream.debounceTime(const Duration(seconds: 2)),
      deviceStream.debounceTime(const Duration(seconds: 2)),
          (List<Map<String, dynamic>> bleList, List<Map<String, dynamic>> deviceList) {
        for (Map<String, dynamic> device in deviceList) {
          final matchingBleDevices = bleList.where((bleData) => bleData['platformName'] == device['friendlyName']).toList();

          if (matchingBleDevices.isNotEmpty) {
            final mergedBleDevice = matchingBleDevices.fold<Map<String, dynamic>>({}, (previousValue, element) {
              return {...previousValue, ...element}; // BLE 데이터 병합
            });
            device['bleData'] = mergedBleDevice;
          }
        }

        // 병합된 리스트 추가
        deviceStreamController.add(deviceList);
        return deviceList;
      },
    ).listen((mergedDeviceList) {
      if (mergedDeviceList.isNotEmpty && !_isSameList(mergedDeviceList, lastDeviceList)) {
        lastDeviceList = List<Map<String, dynamic>>.from(mergedDeviceList); // 깊은 복사
        if (!deviceStreamController.isClosed) {
          print('Added to deviceStreamController: ${mergedDeviceList.length} items');
          deviceStreamController.add(List<Map<String, dynamic>>.from(mergedDeviceList)); // 깊은 복사
        } else {
          print('deviceStreamController is closed, cannot add data');
        }
      }
    }
    );
  }


  // 리스트 중복 validator
  bool _isSameList(List<Map<String, dynamic>> newList, List<Map<String, dynamic>> oldList) {
    if (newList.length != oldList.length) {
      return false;
    }

    for (int i = 0; i < newList.length; i++) {
      if (!mapEquals(newList[i], oldList[i])) {
        return false;
      }
    }

    return true;
  }


  void setupLogListener() async {
    logStreamController.add("log stream init");
    logChannel.setMethodCallHandler((MethodCall call) async {
      final result = call.arguments;
      if (result.contains('error')) {
        print('error result : $result');
        logStreamController.add(result);
      } else {
        logStreamController.add(result);
      }
    });
  }

  Future<void> webOSRequest(uri, payload) async {
    try {
      logD.i("webOS request sent!\nuri: $uri\npayload: $payload");
      await channel.invokeMethod('webOSRequest', {'uri': uri, 'payload': payload});
    } on PlatformException catch (e) {
      logD.w("Failed to request '${e.message}'.");
    }
  }

  Future<void> startScan() async {
    scanTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        logD.i("Scanning started");
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
    bleScanTimer!.cancel();
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
          final bool success = call.arguments['success'];
          final String response = call.arguments['response'];
          print("request status: $success, Response: $response");
          break;
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
