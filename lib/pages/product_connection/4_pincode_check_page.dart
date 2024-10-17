import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/pages/product_connection/5_pincode_connection_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';

import '../../services/connect_sdk_service.dart';

class PincodeCheckPage extends StatefulWidget {
  const PincodeCheckPage({
    super.key,
  });

  @override
  State<PincodeCheckPage> createState() => _PincodeCheckPageState();
}

class _PincodeCheckPageState extends State<PincodeCheckPage> {
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final DeviceService deviceService = DeviceService();
  final LunaService lunaService = LunaService();

  Future webOSInit() async {
    await deviceService.deviceInitialize();
  }

  Future<void> getDeviceInfoAndRequestParingKey() async {
    try {
      final deviceInfo = await deviceService.getWebOSDeviceInfo();
      if (deviceInfo != null) {
        await connectSdkService.requestParingKey(deviceInfo);
      } else {
        print('No device information available');
      }
    } catch (e) {
      print('Error fetching device info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    webOSInit();
    getDeviceInfoAndRequestParingKey();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone 제품 화면에\n8자리 PIN Code를 확인해주세요.",
      topHeight: 70,
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide4),
        ],
      ),
      bottomButton: const BasicButton(
        text: "다음",
        destinationPage: PincodeConnectionPage(),
      ),
    );
  }
}
