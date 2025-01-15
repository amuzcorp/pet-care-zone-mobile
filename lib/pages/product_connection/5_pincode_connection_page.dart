import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/services/ble_service.dart';
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
  BluetoothDevice connectedDevice = FlutterBluePlus.connectedDevices.first;
  final TextEditingController pincodeController = TextEditingController();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final MessageService messageService = MessageService();
  final BleService bleService = BleService();
  final ApiService apiService = ApiService();
  final DeviceService deviceService = DeviceService();
  final LunaService lunaService = LunaService();
  Map<String, dynamic> deviceInfo = {};
  List<String> errorList = [];

  @override
  void initState() {
    super.initState();
    setDeviceInfo();
    connectSdkService.startLogSubscription((data) {
      handleLogEvent(data);
    });
  }

  @override
  void dispose() {
    connectSdkService.logSubscription!.cancel();
    connectSdkService.logSubscription = null;
    pincodeController.dispose();
    super.dispose();
  }

  Future setDeviceInfo() async {
    deviceInfo = await deviceService.getWebOSDeviceInfo();
  }

  void handleLogEvent(String event) async {
    if (mounted) {
      if (event.contains('rejected') || event.contains('invalid')) {
        requestPincode(true);
      }

      if (event.contains('many')) {
        messageHandler("too many pairing requests.");
      }

      if (event.contains('error')) {
        errorList.clear();
        errorList.add(event);
      }

      if (event.contains('registered')) {
        messageHandler("");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
        });
      }
    }
  }

  void requestPincode(bool isShowMessage) async {
    if (isShowMessage) {
      messageHandler("first_use.register.connect_to_device.pincode.connect.error.wrong_pincode".tr());
    } else {
      messageHandler("too many pairing requests.");
    }
    await connectSdkService.requestParingKey(deviceInfo);
  }

  void messageHandler(String message) {
    return messageService.addMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "first_use.register.connect_to_device.pincode.connect.title".tr(),
      topHeight: 70,
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide5),
          PincodeInput(pincodeController: pincodeController),
          boxH(12),
          Text("MAC : ${connectedDevice!.remoteId.toString()}", style: TextStyle(color: ColorConstants.appBarIconColor),),
          StreamBuilder<String>(
            stream: messageService.messageController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Text(errorList.isNotEmpty ? errorList.toString() : "", style: TextStyle(color: ColorConstants.red));
              } else {
                return Text("", style: TextStyle(color: ColorConstants.red));
              }
            },
          ),
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
                  ),
                ],
              )
          ),
          boxH(12),
        ],
      ),
      bottomButton: BasicButton(
        text: "first_use.register.connect_to_device.pincode.connect.entered".tr(),
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
