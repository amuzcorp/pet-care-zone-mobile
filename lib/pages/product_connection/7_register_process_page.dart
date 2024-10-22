import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';

import '../../widgets/images/image_widget.dart';
import '../../widgets/page/basic_page.dart';
import '8_register_complete_page.dart';

class RegisterProcessPage extends StatefulWidget {
  const RegisterProcessPage({super.key});

  @override
  State<RegisterProcessPage> createState() => _RegisterProcessPageState();
}

class _RegisterProcessPageState extends State<RegisterProcessPage> {
  DeviceService deviceService = DeviceService();
  LunaService lunaService = LunaService();
  ConnectSdkService connectSdkService = ConnectSdkService();
  double progressValue = 0;
  List<String> logMessages = [];


  Future handleDeviceRegistrationAndProvision() async {
    try {
      final device = await deviceService.getDeviceInfo();
      if (device == null) {
        print('No device info available.');
        return;
      } else {
        await deviceService.connectToDevice();
      }

      await Future.delayed(const Duration(seconds: 3));
      await lunaService.startProvision();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterCompletePage()));
      }
    } catch (e) {
      _showErrorDialog('Failed to register or provision device: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    handleDeviceRegistrationAndProvision();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      topHeight: 70,
      description: "추가가 끝날 때까지 Pet Care Zone\n과 거리를 가깝게 유지해주세요.",
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide7),
          const SizedBox(height: 20),
          // Progress bar animated over 3 seconds
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 4),
            builder: (context, value, _) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${(value * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5), // Optional: to make the corners rounded
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5), // Match the border radius
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: ColorConstants.grey,
                        color: ColorConstants.lightTeal,
                      ),
                    ),
                  ),
                ],
              );
            },
            onEnd: () {
              print('Progress complete!');
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "곧 끝나요.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
