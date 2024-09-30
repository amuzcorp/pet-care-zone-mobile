import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/pages/product_connection/3_wifi_connection_page.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';

import '../../constants/image_constants.dart';
import '../../constants/size_constants.dart';
import '../../data/models/device_model.dart';
import '../../services/device_service.dart';
import '../../services/wifi_service.dart';
import '../../utils/logger.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final DeviceService deviceService = DeviceService();

  final WifiService wifiService = WifiService();
  StreamSubscription<List<Map<String, dynamic>>>? _deviceStreamSubscription;

  final double itemHeight = 87.0;

  Future<void> bleConnectToDevice(BluetoothDevice device) async {
    print('bleConnectToDevice $device');
    try {
      await device.connect();
      print('Device connected: $device');
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  Future<void> saveDevicesAndNavigate(Map<String, dynamic> device) async {
    /// BLE Data
    final scanResult = device['bleData']['scanResult'];
    final BluetoothDevice bluetoothDevice = scanResult.device;
    print('BLE device: $bluetoothDevice');

    try {
      /// BLE 기기 연결
      await bleConnectToDevice(bluetoothDevice);

      /// DeviceModel 생성
      final deviceModel = DeviceModel(
        serialNumber: device['modelNumber'],
        deviceName: device['friendlyName'],
        deviceIp: device['lastKnownIPAddress'],
      );

      /// WebOS Device 정보 저장
      await deviceService.saveWebOSDeviceInfo(device);

      /// Device 정보 저장
      await deviceService?.saveDeviceInfo(deviceModel);
    } catch (e) {
      print('Error during saveDevicesAndNavigate: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    connectSdkService.bleStartScan();
    connectSdkService.startScan();
    connectSdkService.setupListener();
    _deviceStreamSubscription = connectSdkService.deviceStream.listen((data) {
    });
  }

  @override
  void dispose() {
    _deviceStreamSubscription?.cancel();
    connectSdkService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: connectSdkService.deviceStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            logD.e('Snapshot Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data!.where((device) => device['bleData'] != null).toList();
          print('Devices with BLE data: ${devices.length}');

          final maxContainerHeight = MediaQuery.of(context).size.height - 20.0;
          final containerHeight = (devices.length * itemHeight).clamp(itemHeight, maxContainerHeight);

          if (devices.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(SizeConstants.borderSize),
              child: Container(
                height: containerHeight,
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      key: ValueKey(device['id']),
                      leading: Image.asset(ImageConstants.productConnectionGuide1),
                      title: Text(device['friendlyName'] ?? 'Unknown Device'),
                      subtitle: Text("MAC: ${device['bleData']?['remoteId'] ?? 'Unknown'}"),
                      onTap: () async {
                        await saveDevicesAndNavigate(device);
                        connectSdkService.bleScanTimer?.cancel();
                        if (mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WifiConnectionPage()
                              ),
                          );
                        }
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.only(left: 88.0, right: 30.0),
                    child: Divider(
                      color: ColorConstants.dividerColor,
                    ),
                  ),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      )
    );
  }
}
