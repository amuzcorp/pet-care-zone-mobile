import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/3_wifi_connection_page.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/wifi_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

// import '../../services/ble_service.dart';
import '../../widgets/lists/device_list.dart';
import '../../widgets/page/basic_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final WifiService wifiService = WifiService();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  List<String> macAddresses = [];

  @override
  void initState() {
    super.initState();
    // startScan();
    connectSdkService.startScan();
    connectSdkService.setupListener();
  }

  @override
  void dispose() {
    connectSdkService.stopScan();
    connectSdkService.dispose();
    super.dispose();
  }

  // void startScan() async {
  //   FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
  //
  //   FlutterBluePlus.scanResults.listen((results) async {
  //     for (ScanResult r in results) {
  //       final macAddress = r.device.remoteId.str;
  //       if (!macAddresses.contains(macAddress)) {
  //         macAddresses.add(macAddress);
  //       }
  //       // print('${r.device.advName}\n${r.device.mtu}');
  //       if (r.advertisementData.serviceUuids.isNotEmpty) {
  //         print('ADDADAD : ${r.advertisementData}');
  //         break;
  //       }
  //       // print('${r.device.platformName} found! rssi: ${r.rssi}, mac: $macAddress');
  //       // if (r.device.platformName == 'TargetDeviceName') {
  //       //   FlutterBluePlus.stopScan();
  //       //   connectToDevice(r.device);
  //       //   break;
  //       // }
  //       List<BluetoothDevice> system = await FlutterBluePlus.systemDevices;
  //       for (var d in system) {
  //         print('${r.device.platformName} already connected to! ${r.device.remoteId}');
  //         // if (d.platformName == "myBleDevice") {
  //         //   await r.connect(); // must connect our app
  //         // }
  //       }
  //     }
  //     setState(() {});
  //   });
  // }
  //
  // void connectToDevice(BluetoothDevice device) async {
  //   await device.connect();
  //   setState(() {
  //     connectedDevice = device;
  //   });
  //   discoverServices(device);
  // }
  //
  // void discoverServices(BluetoothDevice device) async {
  //   List<BluetoothService> services = await device.discoverServices();
  //   for (var service in services) {
  //     for (var characteristic in service.characteristics) {
  //       if (characteristic.uuid.toString() == '00002aba-0000-1000-8000-00805f9b34fb') {
  //         setState(() {
  //           targetCharacteristic = characteristic;
  //         });
  //       }
  //     }
  //   }
  // }
  //
  // void writeCharacteristic(String value) async {
  //   if (targetCharacteristic != null) {
  //     Uint8List key = Uint8List(16); // 예제 키 길이
  //     Uint8List uuid = Uint8List.fromList([0x12, 0x34]); // 예제 UUID
  //     makeKey(key, key.length, uuid);
  //
  //     Uint8List original = Uint8List.fromList(utf8.encode(value));
  //     Uint8List result = Uint8List(original.length);
  //     encryptXOR(result, original, original.length, key);
  //
  //     await targetCharacteristic!.write(result);
  //     print('Value written: $value');
  //   }
  // }
  //
  // void startScan() {
  //   FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
  //
  //   FlutterBluePlus.scanResults.listen((results) {
  //     for (ScanResult r in results) {
  //       // Manufacturer Data 체크 및 필터링 추가
  //       if (isTargetDevice(r)) {
  //         FlutterBluePlus.stopScan();
  //         connectToDevice(r.device);
  //         break;
  //       }
  //     }
  //     setState(() {});
  //   });
  // }
  //
  // bool isTargetDevice(ScanResult r) {
  //   // Manufacturer Data를 확인하고 PetCareZone Device 여부 판별
  //   return r.advertisementData.manufacturerData.contains(someCondition);
  // }
  //
  // void connectToDevice(BluetoothDevice device) async {
  //   await device.connect();
  //   setState(() {
  //     connectedDevice = device;
  //   });
  //   discoverServices(device);
  // }
  //
  // void discoverServices(BluetoothDevice device) async {
  //   List<BluetoothService> services = await device.discoverServices();
  //   services.forEach((service) {
  //     service.characteristics.forEach((characteristic) {
  //       if (characteristic.uuid.toString() == 'target-characteristic-uuid') {
  //         setState(() {
  //           targetCharacteristic = characteristic;
  //         });
  //       }
  //     });
  //   });
  // }
  //
  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "연결 가능한 제품",
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          boxH(80),
          FontConstants.inputLabelText('주변 제품'),
          boxH(10),
          DeviceList(
              connectSdkService: connectSdkService,
              destinationPage: const WifiConnectionPage(),
          ),
        ],
      ),
    );
  }
}
