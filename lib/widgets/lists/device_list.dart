import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/pages/product_connection/2_device_list_page.dart';
import 'package:petcarezone/pages/product_connection/3_wifi_connection_page.dart';
import 'package:petcarezone/services/ble_service.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/message_service.dart';

import '../../constants/image_constants.dart';
import '../../constants/size_constants.dart';
import '../../services/device_service.dart';
import '../../utils/logger.dart';
import '../box/box.dart';
import '../indicator/indicator.dart';

class DeviceList extends StatefulWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const DeviceList({super.key, this.onLoadingChanged, required this.isFromWebview});
  final bool isFromWebview;
  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> with RouteAware {
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final BleService bleService = BleService();
  final DeviceService deviceService = DeviceService();
  final MessageService messageService = MessageService();
  final double itemHeight = 87.0;

  Future<void> bleConnectToDevice(BluetoothDevice device) async {
    await device.disconnect();
    await device.connect();
  }

  Future<void> saveDevicesAndNavigate(Map<String, dynamic> device) async {
    widget.onLoadingChanged?.call(true);
    /// BLE Data
    final BluetoothDevice bluetoothDevice = device['scanResult'].device;
    try {
      /// BLE 기기 연결
      await bleConnectToDevice(bluetoothDevice);

      /// BLE Data
      await deviceService.saveBleInfo(bluetoothDevice);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WifiConnectionPage(isFromWebView: widget.isFromWebview),
          ),
        );
      }
    } catch (e) {
      messageService.addMessage("Bluetooth 연결을 다시 진행 후 메뉴를 눌러주세요.");
      logD.e('Error during saveDevicesAndNavigate: $e');
      rethrow;
    } finally {
      widget.onLoadingChanged?.call(false);
    }
  }
  @override
  void initState() {
    super.initState();
    connectSdkService.startBleScan();
  }

  @override
  void dispose() {
    connectSdkService.stopBleScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: Column(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: connectSdkService.bleStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty
              ) {
                return const Expanded(child: GradientCircularLoader());
              }

              if (snapshot.hasError) {
                logD.e('Snapshot Error: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
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
                          leading: Image.asset(ImageConstants.productConnectionGuide3),
                          title: Text(device['platformName'] ?? 'Unknown Device'),
                          subtitle: Text("MAC: ${device['remoteId'] ?? 'Unknown'}"),
                          onTap: () async {
                            await saveDevicesAndNavigate(device);
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
              return const Expanded(child: GradientCircularLoader());
            },
          ),
          boxH(10),
          StreamBuilder<String>(
            stream: messageService.messageController.stream,
            builder: (context, snapshot) {
              String errorText = snapshot.data ?? "";
              return Text(errorText, style: TextStyle(color: ColorConstants.red),);
            },
          ),
        ],
      )
    );
  }
}
