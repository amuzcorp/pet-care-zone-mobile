import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/pages/product_connection/5_pincode_connection_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';

import '../../constants/color_constants.dart';
import '../../data/models/device_model.dart';
import '../../services/connect_sdk_service.dart';
import '../../utils/logger.dart';

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
  final MessageService messageService = MessageService();

  Future saveWebOSDeviceInfo() async {
    final matchedWebosDevice = connectSdkService.matchedWebosDevice;

    logD.i('matchedWebosDevice $matchedWebosDevice');

    if (matchedWebosDevice.isNotEmpty) {
      /// DeviceModel 생성
      final deviceModel = DeviceModel(
        serialNumber: matchedWebosDevice['modelNumber'],
        deviceName: matchedWebosDevice['friendlyName'],
        deviceIp: matchedWebosDevice['lastKnownIPAddress'],
      );

      /// webOS Whole Data 저장
      await deviceService.saveWebOSDeviceInfo(matchedWebosDevice);

      /// webOS 필요한 Data 저장
      await deviceService.saveDeviceInfo(deviceModel);

      await deviceService.deviceInitialize();
    } else {
      messageService.messageController.add("기기 연결에 실패했어요. 뒤로 이동해\nWi-Fi 연결을 다시 시도해 주세요.");
    }
  }

  Future requestParingKey() async {
    try {
      final deviceInfo = await deviceService.getWebOSDeviceInfo();
      if (deviceInfo != null) {
        await connectSdkService.requestParingKey(deviceInfo);
      } else {
        messageService.messageController.add("webOS 연결이 필요해요.\n뒤로 이동해서 다시 Wi-Fi를 연결해 주세요.");
        logD.e('No device information available');
      }
    } catch (e) {
      logD.e('Error fetching device info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    saveWebOSDeviceInfo();
  }

  @override
  void dispose() {
    messageService.messageController.close();
    super.dispose();
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
          StreamBuilder<String>(
            stream: messageService.messageController.stream,
            builder: (context, snapshot) {
              String errorText = snapshot.data ?? "";
              return Text(errorText, style: TextStyle(color: ColorConstants.red),);
            },
          ),
        ],
      ),
      bottomButton: BasicButton(
        text: "다음",
        destinationPage: const PincodeConnectionPage(),
        onPressed: () => requestParingKey(),
      ),
    );
  }
}
