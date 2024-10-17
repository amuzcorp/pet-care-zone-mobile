import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';
import 'package:petcarezone/widgets/inputs/pincode_input.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';

import '6_register_page.dart';

class PincodeConnectionPage extends StatefulWidget {
  const PincodeConnectionPage({super.key});

  @override
  State<PincodeConnectionPage> createState() => _PincodeConnectionPageState();
}

class _PincodeConnectionPageState extends State<PincodeConnectionPage> {
  final TextEditingController pincodeController = TextEditingController();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final DeviceService deviceService = DeviceService();
  final LunaService lunaService = LunaService();

  @override
  void dispose() {
    pincodeController.dispose();
    super.dispose();
  }

  String _handleLogMessage(String message) {
    print('message $message');

    if (message.contains('rejected') || message.contains('Invalid') || message.contains('cancel')) {
      return "*PIN Code가 일치하지 않습니다.";
    } else if (message.contains('many')) {
      return "너무 많은 요청을 보냈어요. 초 후 문구가\n사라지면 다시 시도해주세요.";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone 제품 화면에\n표시된 PIN Code를 입력하세요.",
      topHeight: 70,
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide5),
          PincodeInput(pincodeController: pincodeController),
          const SizedBox(height: 16),
        ],
      ),
      bottomButton: BasicButton(
        text: "입력했어요",
        onPressed: () async {
          await connectSdkService.sendPairingKey(pincodeController.text);
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
          }
        },
      ),
    );
  }
}
