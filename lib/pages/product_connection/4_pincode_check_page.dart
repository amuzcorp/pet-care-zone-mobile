import 'package:flutter/cupertino.dart';
import 'package:petcarezone/constants/image_constants.dart';
import 'package:petcarezone/pages/product_connection/5_pincode_connection_page.dart';
import 'package:petcarezone/services/device_service.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    connectSdkService.deviceStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    deviceService.requestPincode();
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone 제품 화면에\n8자리 PIN Code를 확인해주세요.",
      topHeight: 70,
      guideImage: guideImageWidget(imagePath: ImageConstants.productConnectionGuide2),
      bottomButton: const BasicButton(
        text: "다음",
        destinationPage: PincodeConnectionPage(),
      ),
    );
  }
}
