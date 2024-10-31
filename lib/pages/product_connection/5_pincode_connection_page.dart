import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';
import 'package:petcarezone/widgets/inputs/pincode_input.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';

import '../../constants/color_constants.dart';
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
  final MessageService messageService = MessageService();
  String? lastLog = "";
  int countdown = 0;
  bool isCountdownRunning = false;
  Timer? pincodeTimer;

  @override
  void initState() {
    super.initState();
    connectSdkService.logStream.listen(handleLogEvent);
  }

  @override
  void dispose() {
    pincodeController.dispose();
    pincodeTimer?.cancel();
    super.dispose();
  }

  void handleLogEvent(String event) {
    if (mounted) {
      if (event.contains("rejected") || event.contains('invalid')) {
        messageHandler("*PIN Code가 일치하지 않습니다.");
      }

      if (event.contains("many")) {
        startCountdown();
      }

      if (event.contains('true') || event.contains('registered')) {
        messageHandler("");
      }

      if (event.contains('registered')) {
        connectSdkService.stopScan();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
        });
      }
    }
  }

  messageHandler(String message) {
    return messageService.messageController.add(message);
  }

  void startCountdown() {
    if (isCountdownRunning) return;

    isCountdownRunning = true;
    countdown = 30;

    pincodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;

      if (countdown > 0) {
        messageHandler("*PIN Code 요청이 너무 많아요. $countdown초 후\n뒤로 돌아가 다음 버튼을 다시 눌러주세요.");
      } else {
        timer.cancel();
        pincodeTimer?.cancel();
        isCountdownRunning = false;
        messageHandler("*PIN Code 요청을 다시 시도해 주세요.");
        lastLog = null;
      }
    });
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
          boxH(16),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreamBuilder<String>(
                    stream: messageService.messageController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(snapshot.data!, style: TextStyle(color: ColorConstants.red));
                      } else {
                        return Text("", style: TextStyle(color: ColorConstants.red));
                      }
                    },
                  )
                ],
              )
          ),
          boxH(15),
        ],
      ),
      bottomButton: BasicButton(
        text: "입력했어요",
        onPressed: () async {
          if (pincodeController.text.length < 8){
            messageHandler("*PIN Code 8자리를 입력해 주세요.");
          } else if (pincodeController.text.length == 8){
            messageHandler("");
            await connectSdkService.sendPairingKey(pincodeController.text);
          }
        },
      ),
    );
  }
}
