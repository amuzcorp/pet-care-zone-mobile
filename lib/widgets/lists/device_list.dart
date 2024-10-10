import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/pages/product_connection/3_wifi_connection_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';

import '../../constants/image_constants.dart';
import '../../constants/size_constants.dart';
import '../../data/models/device_model.dart';
import '../../services/device_service.dart';
import '../../services/wifi_service.dart';
import '../../utils/logger.dart';
import '../indicator/indicator.dart';

class DeviceList extends StatefulWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const DeviceList({super.key, this.onLoadingChanged});

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
      await device.connect();
      print("Error connecting to device: $e");
    }
  }


  Future<void> saveDevicesAndNavigate(Map<String, dynamic> device) async {
    widget.onLoadingChanged?.call(true);
    /// BLE Data
    final BluetoothDevice bluetoothDevice = device['scanResult'].device;

    print('ble whole data $device');
    print('BLE device: $bluetoothDevice');
    print('bluetoothDevice ${device['platformName']}');

    try {
      /// BLE 기기 연결
      await bleConnectToDevice(bluetoothDevice);

      /// BLE Data
      await deviceService.saveBleInfo(bluetoothDevice);

      if (connectSdkService.devices.isNotEmpty) {
        print('connectSdkService.devices ${connectSdkService.devices}');
        final webOSDevice = connectSdkService.devices.firstWhere(
              (webOSDevice) => webOSDevice['friendlyName'].trim() == device['platformName'].trim(),
        );

        if (webOSDevice.isNotEmpty) {
          print('webOSDevice $webOSDevice');
          /// DeviceModel 생성
          final deviceModel = DeviceModel(
            serialNumber: webOSDevice['modelNumber'],
            deviceName: webOSDevice['friendlyName'],
            deviceIp: webOSDevice['lastKnownIPAddress'],
          );

          /// webOS Whole Data
          await deviceService.saveWebOSDeviceInfo(webOSDevice);

          /// webOS necessary Data
          await deviceService?.saveDeviceInfo(deviceModel);
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WifiConnectionPage(),
          ),
        );
      }

    } catch (e) {
      print('Error during saveDevicesAndNavigate: $e');
      rethrow;
    } finally {
      widget.onLoadingChanged?.call(false);
    }
  }

  @override
  void initState() {
    super.initState();
    connectSdkService.bleStartScan();
    connectSdkService.startScan();
    connectSdkService.setupListener();
    _deviceStreamSubscription = connectSdkService.deviceStream.listen((data) {
      if(mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    connectSdkService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: connectSdkService.bleStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            logD.e('Snapshot Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: GradientCircularLoader());
          }

            final devices = snapshot.data!.toList();

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
                      title: Text(device['platformName'] ?? 'Unknown Device'),
                      subtitle: Text("MAC: ${device['remoteId'] ?? 'Unknown'}"),
                      onTap: () async {
                        await saveDevicesAndNavigate(device);
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
          return const Center(child: GradientCircularLoader());
        },
      )
    );
  }
}
