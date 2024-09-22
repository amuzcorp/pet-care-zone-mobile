import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';

import '../../constants/image_constants.dart';
import '../../constants/size_constants.dart';
import '../../data/models/device_model.dart';
import '../../services/device_service.dart';
import '../../utils/logger.dart';

class DeviceList extends StatelessWidget {
  final DeviceService? deviceService = DeviceService();
  final ConnectSdkService connectSdkService;
  final Widget destinationPage;

  DeviceList({
    super.key,
    required this.connectSdkService,
    required this.destinationPage,
  });

  final double itemHeight = 87.0;

  /// save WebOS device info whole data
  Future saveWebOSDeviceInfo(device) async {
    print('deviceInfo save $device');
    await deviceService?.saveWebOSDeviceInfo(device);
  }

  /// save device info except for deviceID & stop scan
  Future saveDeviceInfo(deviceModel) async {
    await deviceService?.saveDeviceInfo(deviceModel);
    await connectSdkService.stopScan();
  }

  Future saveDevicesAndNavigate(BuildContext context, Map<String, dynamic> device) async {
    final deviceModel = DeviceModel(
      serialNumber: device['modelNumber'],
      deviceName: device['friendlyName'],
      deviceIp: device['lastKnownIPAddress'],
    );

    saveWebOSDeviceInfo(device);
    saveDeviceInfo(deviceModel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => destinationPage,
      ),
    );
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

          final devices = snapshot.data!;
          final maxContainerHeight = MediaQuery.of(context).size.height - 20.0;
          final containerHeight = (devices.length * itemHeight).clamp(itemHeight, maxContainerHeight);

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
                    key: ValueKey(device['id']), // 고유한 키 추가
                    leading: Image.asset(ImageConstants.productConnectionGuide1),
                    title: Text(device['friendlyName'] ?? 'Unknown Device'),
                    subtitle: Text("IP: ${device['lastKnownIPAddress'] ?? 'Unknown IP'}"),
                    onTap: () => saveDevicesAndNavigate(context, device),
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
        },
      ),
    );
  }
}
