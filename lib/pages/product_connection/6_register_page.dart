import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/pages/product_connection/7_register_process_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
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
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final LunaService lunaService = LunaService();

  Future navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterProcessPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceModel?> (
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
              description: "first_use.register.connect_to_device.register_guide.title".tr(),
              contentWidget: guideImageWidget(imagePath: ImageConstants.productConnectionGuide6),
            );
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
