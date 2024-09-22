import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/services/wifi_service.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../widgets/page/basic_page.dart';

class BLEService extends StatefulWidget {
  @override
  _BLEServiceState createState() => _BLEServiceState();
}

class _BLEServiceState extends State<BLEService> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  List<String> macAddresses = [];

  WifiService wifiService = WifiService();

  @override
  void initState() {
    super.initState();
    // wifiService.initialize();
    // startScan();
  }

  void startScan() {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final macAddress = r.device.remoteId.str;
        if (!macAddresses.contains(macAddress)) {
          macAddresses.add(macAddress);
        }
        print('${r.device.advName}');
        print('${r.device.platformName} found! rssi: ${r.rssi}, mac: $macAddress');
        if (r.device.platformName == 'TargetDeviceName') {
          FlutterBluePlus.stopScan();
          connectToDevice(r.device);
          break;
        }
      }
      setState(() {});
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });
    discoverServices(device);
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == '00002aba-0000-1000-8000-00805f9b34fb') {
          setState(() {
            targetCharacteristic = characteristic;
          });
        }
      }
    }
  }

  void writeCharacteristic(String value) async {
    if (targetCharacteristic != null) {
      Uint8List key = Uint8List(16); // 예제 키 길이
      Uint8List uuid = Uint8List.fromList([0x12, 0x34]); // 예제 UUID
      makeKey(key, key.length, uuid);

      Uint8List original = Uint8List.fromList(utf8.encode(value));
      Uint8List result = Uint8List(original.length);
      encryptXOR(result, original, original.length, key);

      await targetCharacteristic!.write(result);
      print('Value written: $value');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const BasicPage(
      showAppBar: true,
      description: "연결 가능한 제품",
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // boxH(80),
          // FontConstants.inputLabelText('주변 제품'),
          // boxH(10),
          // DeviceList(
          //   connectSdkService: connectSdkService,
          //   destinationPage: const WifiConnectionPage(),
          // ),
        ],
      ),
    );
  }
}

void makeKey(Uint8List key, int keyLength, Uint8List uuid) {
  int keyValue = 0;
  if ((uuid[1] & 0x01) == 0x01) {
    keyValue = 1;
  }

  int uuidIndex = 0;
  for (int i = 0; i < keyLength; i++) {
    if (i % 2 == keyValue) {
      key[i] = key[i] ^ uuid[(uuidIndex++) % 2];
    }
  }
}

int encryptXOR(Uint8List result, Uint8List original, int originalLength, Uint8List key) {
  if (original == null || key == null || originalLength <= 0) {
    return -1;
  }

  for (int i = 0; i < originalLength; i++) {
    result[i] = original[i] ^ key[i % key.length];
  }

  return 1;
}
