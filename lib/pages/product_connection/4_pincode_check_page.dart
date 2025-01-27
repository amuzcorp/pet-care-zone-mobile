import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
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

  Future requestParingKey() async {
    try {
      final deviceInfo = await deviceService.getWebOSDeviceInfo();
      if (deviceInfo != null) {
        await connectSdkService.requestParingKey(deviceInfo);
      } else {
        messageService.addMessage("Wi-Fi 연결을 실패했어요.\n뒤로 이동해서 다시 Wi-Fi를 연결해 주세요.");
        logD.e('No device information available');
      }
    } catch (e) {
      logD.e('Error fetching device info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    connectSdkService.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "first_use.register.connect_to_device.pincode.check.title".tr(),
      topHeight: 70,
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide4),
        ],
      ),
      bottomButton: BasicButton(
        text: "first_use.register.connect_to_device.pincode.check.next".tr(),
        destinationPage: const PincodeConnectionPage(),
        onPressed: () => requestParingKey(),
      ),
    );
  }
}
