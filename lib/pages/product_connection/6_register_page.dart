import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/pages/product_connection/7_register_process_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/widgets/page/basic_page.dart';
import '../../data/models/device_model.dart';
import '../../widgets/images/image_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final DeviceService deviceService = DeviceService();

  Future navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      return Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterProcessPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceModel?>(
      future: deviceService.getDeviceInfo(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No device info available.'));
            }

            navigate();
            return BasicPage(
              showAppBar: true,
              description: "Pet Care Zone 1m 이내에서\n기다려주세요. 가까울 수록 연결이\n잘 돼요.",
              contentWidget: guideImageWidget(imagePath: ImageConstants.productConnectionGuide4),
            );
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }


}