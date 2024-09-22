import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/inputs/pincode_input.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';

import '../../data/models/device_model.dart';
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

  final StreamController<DeviceModel?> deviceInfoController = StreamController<DeviceModel?>();

  @override
  void initState() {
    super.initState();
    connectSdkService.setupLogListener();
    loadDeviceInfo();
  }

  @override
  void dispose() {
    pincodeController.dispose();
    connectSdkService.dispose();
    deviceInfoController.close();
    super.dispose();
  }

  Future<void> loadDeviceInfo() async {
    final deviceModel = await deviceService.getDeviceInfo();
    deviceInfoController.add(deviceModel);
  }

  Future<String> getDeviceId(String deviceIp) async {
    Map result = await lunaService.startProvision(deviceIp);
    return result["iotDeviceId"];
  }

  String _handleLogMessage(String message) {
    if (message.contains('rejected') || message.contains('Invalid') || message.contains('cancel')) {
      return "*PIN Code가 일치하지 않습니다.";
    } else if (message.contains('many')) {
      return "너무 많은 요청을 보냈어요. 10초 후 문구가\n사라지면 다시 시도해주세요.";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceModel?>(
      stream: deviceInfoController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data != null) {
          final deviceModel = snapshot.data!;
          return BasicPage(
            showAppBar: true,
            description: "Pet Care Zone 제품 화면에\n표시된 PIN Code를 입력하세요.",
            topHeight: 70,
            contentWidget: Column(
              children: [
                PincodeInput(pincodeController: pincodeController),
                Expanded(
                  child: StreamBuilder<String>(
                    stream: connectSdkService.logStream,
                    builder: (context, logSnapshot) {
                      final logMessage = logSnapshot.data ?? '';
                      final displayMessage = _handleLogMessage(logMessage);

                      return Text(
                        displayMessage,
                        style: TextStyle(color: displayMessage.isNotEmpty ? ColorConstants.red : Colors.transparent),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            bottomButton: BasicButton(
              text: "입력했어요",
              onPressed: () async {
                await connectSdkService.sendPairingKey(pincodeController.text);
                String deviceId = await getDeviceId(deviceModel.deviceIp!);

                if (deviceId.isNotEmpty) {
                  final updatedDeviceModel = deviceModel.copyWith(deviceId: deviceId);
                  await deviceService.saveDeviceInfo(updatedDeviceModel);
                  if (mounted) {
                    connectSdkService.logStreamController.close();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                  }
                }
              },
            ),
          );
        } else {
          return const Center(child: Text('No device info found.'));
        }
      },
    );
  }
}
